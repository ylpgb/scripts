#
# A Simple HTTP server that uses HTTP::Server::Brick
# to handle HTTP requests/replies and also provides
# DB access routines to simplify database accesses
#


package HTTP::SimpleServer;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use DBI;
use HTTP::Server::Brick;
use HTTP::Status;
use Data::UUID;
use JSON;

#use Carp 'verbose';
#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };
use Carp;
# 
# Constructor
#
# Options:
#   port         => <port-to-listen-on>,
#   content_path => '<path-to-static-content>',
#   use_auth_db  => <name-of-db-containing-user-sessions (must be in db_map)>,
#   get_user_info_callback => <func-to-call-to-retrieve-additional-info-for-user>,
#   db_map       => {<name>     => {name     => <name>,
#                                   host     => <host>,
#                                   port     => <port>,
#                                   user     => <username>,
#                                   password => <password>},
#                    <name2>    => {...},
#                   }
#   debug => <0|1>,
#
#   Note: to allow user sessions to work, you must specify (with session_db)
#   the name of the DB that contains the following tables
#   
#     - sessions        (id INT, session_id VARCHAR(255), user_id INT)
#     - users           (id INT, name VARCHAR(128), username VARCHAR(64))
#     - user_properties (id INT, attr_name VARCHAR(128), attr_val TEXT)
#
#   The following methods exist to manage users:
#     addUser(username => <full-email>, name => <full-name>, password => <password>)
#     changeUser(username => <full-email>, name => <full-name>, password => <password>)
#     getUser(username => <full-email>) - returns: name and list of properties
#
sub new {
  my $class = shift;
  my %args = @_;

  my $self = {};

  $self->{port}                   = $args{port} || 80;
  $self->{content_path}           = $args{content_path} || "";
  $self->{debug}                  = $args{debug}  || 0;
  $self->{db_map}                 = $args{db_map} || {};
  $self->{use_auth_db}            = $args{use_auth_db} || "";
  $self->{get_user_info_callback} = $args{get_user_info_callback};

  ## Private class data access.

  $self->{server} = HTTP::Server::Brick->new( 
    port => $args{port},
    fork => 1);

  if ($self->{content_path} ne "") {
    $self->{server}->mount( '/' => {
      path => getContentPath($self->{content_path})
                            });
  }

  bless($self, $class);

  return $self;
}

sub start {
  my ($self) = @_;

  $self->{server}->start;

}


#
# add_dispatcher
#
# Define a new function dispatcher
#
# path  => <path-for-this-dispatcher>
# type => path | callback | json | jsonp
# callback => <func-pointer> # only used for callback type
# cmd_selector => <json-key> # Used to select a named value in the JSON to use as the dispatch pivot
# disp_map => {<cmd1> => {func => <function>, dbs => ["<db1>", "<db2>"]}, ...}

sub add_dispatcher {
  my ($self, %args) = @_;

  croak("Required parameter 'path' is missing") if (!$args{path});
  croak("Required parameter 'type' is missing") if (!$args{type});

  if ($args{type} =~ /^json(p)?$/) {
    croak("Required parameter 'cmd_selector' is missing for $args{type} dispatcher") if (!$args{cmd_selector});
    croak("Required parameter 'disp_map' is missing for $args{type} dispatcher") if (!$args{disp_map});
  }

  if ($args{type} eq "path") {
    $self->{server}->mount($args{path} => {
      path => getContentPath($args{type})});
  }
  elsif ($args{type} eq "callback") {
    $self->{server}->mount($args{path} => {
      handler => sub { $self->serviceCallback($args{callback}, $args{dbs}, @_)},
      wildcard => 1,
    });
  }
  elsif ($args{type} eq "json") {
    my $map      = $args{disp_map};
    my $selector = $args{cmd_selector};
    $self->{server}->mount($args{path} => {
      handler => sub { $self->serviceJsonRequest($map, $selector, @_)},
      wildcard => 1,
    });
  }
  elsif ($args{type} eq "jsonp") {
    my $map      = $args{disp_map};
    my $selector = $args{cmd_selector};
    $self->{server}->mount($args{path} => {
      handler => sub { $self->serviceJsonpRequest($map, $selector, @_)},
      wildcard => 1,
    });
  }
}


#
# serviceCallback - Handle a straight callback
#
sub serviceCallback {
  my ($self, $cb, $dbsToOpen, $req, $res) = @_;

  my $dbs = $self->openDbs($dbsToOpen) if $dbsToOpen;
  my $remoteIp = $req->header("X-Remote-IP") || $req->header('x-brick-remote-ip');
  return {status => 'error',
          error => "Failed to communicate with required databases"} if $dbsToOpen && !defined($dbs);

  
  my $content = &{$cb}($self, $req, $remoteIp, @{$dbs});
  $res->add_content($content);

  return 1;

}


#
# serviceJsonRequest - Handle requests with JSON bodies and an embedded command
#
sub serviceJsonRequest {
  my ($self, $map, $selector, $req, $res) = @_;
  
  my $uri      = $req->uri();
  my $content  = $req->content();
  my $remoteIp = $req->header("X-Remote-IP") || $req->header('x-brick-remote-ip');

  $content =~ s/\n/ /g;
  $content =~ s/^(.{1,90}).*/$1/g;
  print "Received: $content\n";
  my $jsonReq = decode_json($req->content());
  my $result  = $self->processRequest($map, $selector, $req, $jsonReq, $remoteIp, $res);
  my $json    = encode_json($result);

  $res->add_content($json);

  return 1;

} # serviceJsonRequest #


#
# serviceJsonpRequest - Handle requests with JSONP bodies
#
sub serviceJsonpRequest {
  my ($self, $map, $selector, $req, $res) = @_;

  my $uri               = $req->uri();
  my $remoteIp          = $req->header("X-Remote-IP") || $req->header('x-brick-remote-ip');
  my ($params)          = ($uri =~ /\?(.*)/);
  my ($callback, $rest) = ($params =~ /callback=([^&]+)&?(.*)/);

  my @otherParams = split(/&/, $rest);

  my $json;
  foreach my $param (@otherParams) {
    if ($param =~ /%7B/) {
      $param =~ s/%([\da-fA-F]{1,2})/chr(hex($1))/ge;
      $json = $param;
    }
  }
  my $jsonReq = decode_json($json);

  my $result = $self->processRequest($map, $selector, $req, $jsonReq, $remoteIp, $res);

  # Do the JSON wrapping
  $json = $callback . "(" . encode_json($result) . ")";

  $res->add_content($json);
  $res->header('Content-Type', 'application/javascript');

  return 1;

} # serviceJsonpRequest #

#
# handleSessionPre - 
# Do the session handling before servicing the JSON request 
#
sub handleSessionPre {
  my ($self, $req, $jsonReq, $authDb) = @_;

  delete($req->{_session});

  return if ref($req) eq "HASH";
  my $cookieStr = $req->header('Cookie');
  return if !defined $cookieStr;

  my @cookies = split(/;/, $cookieStr);

  my $sessionId;
  foreach my $cookie (@cookies) {
    my ($name, $val) = split(/=/, $cookie);
    if (defined($name) && $name =~ /^session_id$/i) {
      $sessionId = $val;
      last;
    }
  }

  if ($sessionId) {
    my $userInfo = $self->getUserFromSessionId($sessionId, $authDb);
    if ($userInfo) {
      $jsonReq->{_session}{currentUser}{id}       = $userInfo->{id};
      $jsonReq->{_session}{currentUser}{username} = $userInfo->{name};
      $jsonReq->{_session}{sessionId}             = $sessionId;
    }
  }

  return {};

} # handleSessionPre #


#
# handleSessionPost 
# Do the session handling after servicing the JSON request 
#
sub handleSessionPost {
  my ($self, $res, $jsonRes, $db) = @_;

  return if !defined($jsonRes) || ref($jsonRes) ne "HASH";

  my $session = $jsonRes->{_session};

  if ($session) {
    if ($session->{sessionId}) {
      my $expire = localtime(time() + 365*3600*24);
      my $secure = $self->{ssl} ? ", Secure" : "";
      $res->header("Set-Cookie", "session_id=$session->{sessionId}; Expires=$expire $secure");
    }
    if ($session->{logout}) {
      my $epoch = localtime(0);
      $res->header("Set-Cookie", "session_id=deleted; Expires=$epoch");
      $self->logout($jsonRes->{_session}{sessionId}) if $jsonRes->{_session}{sessionId};
    }
  }
  
  delete($res->{_session});

} # handleSessionPost #


#
# processRequest - Handle the embedded JSON request
#
sub processRequest {
  my ($self, $map, $selector, $req, $jsonReq, $remoteIp, $res) = @_;

  my $cmd = $map->{$jsonReq->{$selector}};
  if (!defined($cmd)) {
    carp("Undefined request type '$jsonReq->{$selector}' in JSON request with command selector $selector");
    return {status => 'error',
            error => "Invalid request type: $jsonReq->{type}"};
  }

  my $authDbIdx;
  if ($self->{use_auth_db}) {
    my $idx = 0;
    map {
      if ($_ eq $self->{use_auth_db}) {
        $authDbIdx = $idx;
      }
      $idx++;
    } @{$cmd->{dbs}};
    if (!defined($authDbIdx)) {
      push(@{$cmd->{dbs}}, $self->{use_auth_db});
      $authDbIdx = scalar(@{$cmd->{dbs}}) - 1;
    }
  }

  my $dbs = $self->openDbs($cmd->{dbs}) if $cmd->{dbs};
  return {status => 'error',
          error => "Failed to communicate with required databases"} if $cmd->{dbs} && !defined($dbs);

  if ($self->{use_auth_db}) {
    my $rc = $self->handleSessionPre($req, $jsonReq, $dbs->[$authDbIdx]) ;
    return $rc if $rc->{error};
    if ($cmd->{auth} && !defined($jsonReq->{_session})) {
      return {error => "Authorization is required for this request"};
    }
  }
  
  my $result = &{$cmd->{func}}($self, $jsonReq, $remoteIp, @{$dbs});

  $self->handleSessionPost($res, $result, $dbs->[$authDbIdx]) if $self->{use_auth_db};

  return $result;

} # processRequest #


#
# getUserFromSessionId - 
#
# Look into the session database and get the user info from it 
#
sub getUserFromSessionId {
  my ($self, $sessionId, $db) = @_;

  my $user = $self->sql($db, "select users.name, users.id from users, sessions where user_id=users.id and session_id=?",
                        $sessionId);

  return $user->[0];

} # getUserFromSessionId #


#
# login - Handle user logins (must be called by the app code)
#
sub login {
  my ($self, $req, $db) = @_;

  my $uname  = $req->{username};
  my $passwd = $req->{password};

  if (!defined($uname) || !defined($passwd)) {
    return {error => "Missing username or password in logon request"};
  }

  my $userInfo = $self->getUserInfo($db, $uname);

  if ($userInfo->{waitingForValidation}) {
    return {error => "You must validate this user before you can sign in with it"};
  }

  if (!defined($userInfo->{name})) {
    goto fail;
  }

  if (!defined($userInfo->{password}) || $userInfo->{password} eq "") {
    goto fail;
  }
  else {
    my $check = crypt($passwd, $userInfo->{password});
    if ($check eq $userInfo->{password}) {
      goto passed;
    }
    goto fail;
  }

 passed:

  if ($req->{_session} && $req->{_session}{currentUser}{name} eq $uname) {
    # No need to create a new session
    return {loggedIn => 1, 
            _session => $req->{_session},
            username => $uname,
            name => $userInfo->{name}};
  }

  my $uid = new Data::UUID;
  my $sessionId = $uid->to_string($uid->create()) . "-" . int(rand(0xffffffff));

  $self->storeUserSessionId($uname, $sessionId, $db);

  my $res;
  $res->{_session}{sessionId} = $sessionId;
  $res->{loggedIn}         = 1;
  $res->{username}         = $uname;
  $res->{name}             = $userInfo->{name};

  return $res;

 fail:
    return {loggedIn => 0,
            _session => {logout => 1},
            error => "User '$uname' does not exist or has invalid password"};

}

#
# storeUserSessionId - Put the session information into the auth database 
#
sub storeUserSessionId {
  my ($self, $user, $sessionId, $db) = @_;

  my $userId = $self->getUserId($db, $user);

  return undef if !defined($userId);

  #$self->sql($self->{db}, "delete from sessions where user_id=?",
  #           $userId);
  $self->sql($db, "insert into sessions (user_id, session_id) values (?, ?)",
             $userId, $sessionId);

  return 1;

} # storeuserSessionId #



#
# logout
#
# Do the required stuff to forget a user's session
#
sub logout {
  my ($self, $req, $db) = @_;  
  
  if ($req->{_session}) {
    my $sessionId = $req->{_session}{sessionId};
    print "Removing session: $sessionId\n";
    $self->sql($db, "delete from sessions where session_id=?",
               $sessionId) if $sessionId;
  }

  return {status => "ok"};
}


#
# create
#
# Create a new user 
#
sub createUser {
  my ($self, $req, $db, $validationCallback) = @_;  
  
  if (!defined($req->{username}) ||
      !defined($req->{password})) {
    return {error => "Missing username or password"};
  }

  my $uname    = $req->{username};
  my $password = $req->{password};

  my $userInfo = $self->getUserInfo($db, $uname);

  if ($userInfo) {
    # Already a user with this name
    if ($userInfo->{password}) {
      return {error => "The username $uname already exists"};
    }
  }

  my $salt = $self->_genSalt();

  $self->setUserInfo($db, $uname,
                     password => crypt($password, $salt)) || 
                         return {error => "Failed to create user $uname"};

  if ($validationCallback) {
    my $uid = new Data::UUID;
    srand();
    my $validationId = $uid->to_string($uid->create()) . "-" . int(rand(0xffffffff));
    $self->setUserInfo($db, $uname,
                       waitingForValidation => 1,
                       validationId => $validationId) || 
                           return {error => "Failed to create user $uname"};
    &{$validationCallback}($uname, $validationId);
  }
  
  return {status => "ok"};

}


#
# resetPassword
#
# Reset a user's password
#
sub resetPassword {
  my ($self, $req, $db, $resetCallback) = @_;  
  
  if (!defined($req->{username})) {
    return {error => "Missing username"};
  }

  my $uname    = $req->{username};
  my $userInfo = $self->getUserInfo($db, $uname);

  if (!$userInfo) {
    # No user with this name
    return {error => "The username $uname does not exist"};
  }

  $self->sql($db, "delete from user_properties where user_id=? and " .
             " (attr_name = 'passwordResetId')",
             $userInfo->{id});

  my $uid = new Data::UUID;
  my $resetId = $uid->to_string($uid->create());
  $self->setUserInfo($db, $uname,
                     passwordResetId => $resetId) || 
                         return {error => "Failed to reset password"};

  if ($resetCallback) {
    &{$resetCallback}($uname, $resetId);
  }
  
  return {status => "ok"};

}


#
# resetPasswordConfirm
#
# Reset a user's password
#
sub resetPasswordConfirm {
  my ($self, $req, $db, $resetCallback) = @_;  
  
  if (!defined($req->{resetId})) {
    return {error => "Missing reset identifier"};
  }
  
  if (!defined($req->{password1}) || !defined($req->{password2})) {
    return {error => "Missing a password"};
  }

  if ($req->{password1} ne $req->{password2}) {
    return {error => "Password mismatch"};
  }
      
  my $userInfo = $self->sql($db, "select user_id as id, name from users, user_properties where " .
                            "users.id=user_properties.user_id and attr_name = 'passwordResetId' and attr_val=?",
                            $req->{resetId});
      
  if (!$userInfo->[0]) {
    # No user with this name
    return {error => "Invalid reset identifier - perhaps it has expired or been used before"};
  }
      
  $self->sql($db, "delete from user_properties where user_id=? and " .
             " (attr_name = 'passwordResetId')",
             $userInfo->[0]{id});
      

  my $rc = $self->changePassword({username         => $userInfo->[0]{name},
                                  'new-password-1' => $req->{password1},
                                  'new-password-2' => $req->{password2}},
                                 $db, undef, 1);

  return $rc if $rc->{error};

  if ($resetCallback) {
    &{$resetCallback}($userInfo->[0]{name});
  }
  
  return {status => "ok"};

}


#
# changePassword
#
# Change a user's password 
#
sub changePassword {
  my ($self, $req, $db, $validationCallback, $skipCurrentPasswordCheck) = @_;  
  
  if (!defined($req->{username}) ||
      (!$skipCurrentPasswordCheck && !defined($req->{password})) ||
      !defined($req->{'new-password-1'}) ||
      !defined($req->{'new-password-2'})) {
    return {error => "Missing username or password"};
  }

  if ($req->{'new-password-1'} ne $req->{'new-password-2'}) {
    return {error => "New passwords do no match"};
  }

  my $uname    = $req->{username};
  my $password = $req->{password};

  my $userInfo = $self->getUserInfo($db, $uname);

  if (!$userInfo) {
    return {error => "Invalid username or password"};
  }


  if (!$skipCurrentPasswordCheck) {
    my $check = crypt($req->{password}, $userInfo->{password});
    if ($check ne $userInfo->{password}) {
      return {error => "Invalid username or password"};
    }
  }

  my $salt = $self->_genSalt();

  $self->setUserInfo($db, $uname,
                     password => crypt($req->{'new-password-1'}, $salt)) || 
                         return {error => "Failed to change password for $uname"};

  return {status => "ok"};

}


#
# validateUser - Called to mark a user as having a valid email address
#
sub validateUser {
  my ($self, $db, $validationId) = @_;

  my $userId = $self->sql($db, "select user_id from user_properties where attr_name='validationId' ".
                          " and attr_val=?",
                          $validationId);
  if ($userId->[0]) {
    $userId = $userId->[0]{user_id};

    $self->sql($db, "delete from user_properties where user_id=? and " .
               " (attr_name = 'validationId' or attr_name = 'waitingForValidation')",
               $userId);
    
  }

}


#
# getUserInfo - Return all the information stored for a user 
#
sub getUserInfo {
  my ($self, $db, $user) = @_;

  my $userInfo = $self->sql($db, "select * from users where name=?",
                            $user);

  return undef if scalar(@{$userInfo}) == 0;

  my $props = $self->sql($db, "select attr_name, attr_val from user_properties where user_id=?",
                         $userInfo->[0]{id});

  my $result = $userInfo->[0];
  foreach my $prop (@{$props}) {
    $result->{$prop->{attr_name}} = $prop->{attr_val};
  }

  if ($self->{get_user_info_callback}) {
    &{$self->{get_user_info_callback}}($user, $result);
  }

  return $result;

}

#
# setUserInfo - Set the user's information in the database. Create the user if necessary
#
sub setUserInfo {
  my ($self, $db, $user, %props) = @_;

  my $userId = $self->getUserId($db, $user, 1);

  if (!defined($userId)) {
    return undef;
  }

  foreach my $name (keys(%props)) {
    $self->sql($db, "delete from user_properties where user_id=? and attr_name=?",
               $userId, $name);
    $self->sql($db, "insert into user_properties (attr_name, attr_val, user_id) values (?,?,?)",
               $name, $props{$name}, $userId);
  }

  return 1;

} # setUserInfo #


# getUserId 
#
# This will check the cache then the DB for the requested user. If not
# present, it will simply add it to the DB and cache and return the new ID
#
sub getUserId {
  my ($self, $db, $user, $createIfMissing) = @_;

  return undef                   if !defined($user);
  return $self->{userIds}{$user} if  defined($self->{userIds}{$user});


  my $userInfo = $self->sql($db, "select id from users where name=?;",
                            $user);

  if (scalar(@{$userInfo})) {
    $self->{userIds}{$user} = $userInfo->[0]{id};
    return $userInfo->[0]{id};
  }

  if ($createIfMissing) {

    print "Creating new user: $user\n";
    $self->sql($db, "insert into users (name) values (?);",
               $user);
    my $id = $db->last_insert_id(undef, undef, undef, undef);
    if (defined($id)) {
      $self->{userIds}{$user} = $id;
      return $id;
    }

    print "Failed to insert the user\n";

  }
  return undef;

} # getUserId #



#
# openDbs - 
#
# This function will open the requested DBs and return handles to them. 
#
sub openDbs {
  my ($self, $dbList) = @_;

  my @dbs;
  foreach my $name (@{$dbList}) {
    my $dbInfo = $self->{db_map}{$name};
    croak("Unknown DB name '$name'") if !defined($dbInfo);
    my $db = $self->connectToDb($dbInfo->{host}, $dbInfo->{port},
                                $dbInfo->{name}, $dbInfo->{user},
                                $dbInfo->{password});
    $db->{mysql_auto_reconnect} = 1;
    return undef if !defined($db);
    push(@dbs, $db);
  }

  return \@dbs;

} # openDbs #


#
# getContentPath - Figure out the path to the static content 
#
sub getContentPath {
  my ($inPath) = @_;

  if ($inPath =~ /^\//) {
    return $inPath;
  }

  # Relative path to the script
  return "$FindBin::Bin/$inPath";

} # getContentPath #

#
# connectToDb - 
#
sub connectToDb {
  my ($self, $dbHost, $dbPort, $dbName, $dbUser, $dbPass) = @_;
  my $db;

  $db = DBI->connect("DBI:mysql:host=$dbHost:port=$dbPort;database=$dbName", 
                     $dbUser, $dbPass);
  
  if (!$db) {
    print "The user \"$dbUser\" could not connect to database \"$dbName\".  ". 
        "The error message returned is: " . $DBI::errstr;
    exit;
    return (undef);
  }

  return $db;

} # connectToDb #


#
# Split out parameters and decode them
#
sub parseHttpParams {
  my ($self, $text) = @_;

  my @params = split(/&/, $text);

  my %params;

  foreach my $param (@params) {
    my ($key, $val) = ($param =~ /^\s*([^=]+)=\s*(.*)/);
    if ($key && $val) {
      if ($val) {
        $val =~ s/\+/ /g;
        $val =~ s/%([a-fA-F0-9]{2})/chr(hex($1))/ge;
      }
      $params{$key} = $val;
    }
  }
  
  return \%params;

}


#
# Do an SQL request to the database
#
sub sql {
  my ($self, $db, $sql, @args) = @_;

  my $isSelect = 1;
  if ($sql !~ /^select |^show |^describe /i) {
    $isSelect = 0;
  }

  my $query  = $db->prepare($sql);
  my $status = $query->execute(@args);

  if (!$status) {
    carp("SQL '$sql' failed: " . $db->errstr);
  }

  my @res;
  while ($isSelect) {
    my $info = $query->fetchrow_hashref;
    last if !defined $info;
    push(@res, $info);
  }
  
  return \@res;

} # sql #


sub doSqlQuery {
  return sql(@_);
}


#
# _genSalt
#
# Internal function to create a salt for passwords 
#
sub _genSalt {
  my ($self) = @_;  

  my $salts=
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./";
  my $salt = '$1$';

  srand();
  for my $c (0..7) {
    $salt .= substr($salts, rand(64), 1);
  }

  return $salt;

}

1;
