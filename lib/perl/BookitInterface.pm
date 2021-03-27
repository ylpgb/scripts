#############################################################################
##
## BookitInterface
##
## Perl module for accessing the bookit server and thus the bookit 
## database
##
#############################################################################

package BookitInterface;

use strict;
use warnings;
use Data::Dumper;
use Carp;
use base 'Exporter';

use LWP::UserAgent;
use HTTP::Cookies;
use JSON;

our @EXPORT_OK = ();

#############################################################################
## constants
##
#############################################################################
use constant { 
    OK   => 0,
    FAIL => 1,
};

my $COOKIE_DIR = "%s/.bookit";
my $COOKIE_JAR = "%s/.bookit/cookies";

my $FIXED_RESOURCE_TYPES = { 
    dev169          => 'Appliance',
    dev231          => 'Appliance',  
    dev232          => 'Appliance',
    'ad-stress'     => 'PerfNetwork',
    'san-130-156'   => 'PerfHost',
    Broken          => 'Group',
    'psg-win7'      => 'PerfHost',
};


#############################################################################
## new - Open connection to the server
##
#############################################################################
sub new { 
   my $class = shift;
   my %args = @_;

   map {croak("Missing required parameter $_") if !defined($args{$_})} qw{ Server };

   my $self = { ServerUri => $args{Server},
                Server    => __connectToServer($args{Server}),
              };

   croak ("Unable to connect to bookit server at $args{Server}") if !$self->{Server};
 
   bless($self, $class);
 
   return $self;

} # new #


##############################################################################
## Unblessed helper functions
##
##############################################################################
sub __setupCookieJar { 

    my $home = $ENV{HOME} || $ENV{USERPROFILE};
    $home = (glob('~'))[0] if !defined $home;
    croak("Cannot determine home directory") if !defined $home;

    my $dir = sprintf($COOKIE_DIR, $home);
    `mkdir -p $dir`;
    croak("Cannot create cookie directory $dir") if $?;
    `chmod 700 $dir`;

    my $jar = sprintf($COOKIE_JAR, $home);
    `chmod 600 $jar` if (-r $jar);
    croak("Cannot create cookie jar $jar") if !(-e $jar);

    return $jar;

}
    
sub __connectToServer { 
    my $server = shift();

    return LWP::UserAgent->new( cookie_jar => HTTP::Cookies->new( file => __setupCookieJar(), autosave => 1 ));

}

sub __requestFailed { 
    my $response = shift();
    return 1 if !defined $response || !$response->{Success};
}

sub __normalizeResourceName { 
    my $name = shift();
    return "lab-128-$1" if $name =~ /^a(\d+)$/i;
    return "lab-129-$1" if $name =~ /^b(\d+)$/i;
    return "lab-130-$1" if $name =~ /^c(\d+)$/i;
    return "lab-$1-$2"  if $name =~ /lab-*(1[23][890])-(\d+)/i;
    return "lab-$1-$2"  if $name =~ /192\.168\.(\d+)\.(\d+)/;
    return $name;
}

sub __getIpAddress { 
    my $name = shift();
    return "192.168.$1.$2"  if $name =~ /^lab-(\d+)-(\d+)$/i;
    return "192.168.1.$1"   if $name =~ /^dev(\d+)$/i;
    return "192.168.128.$1" if $name =~ /^a(\d+)$/i;
    return "192.168.129.$1" if $name =~ /^b(\d+)$/i;
    return "192.168.130.$1" if $name =~ /^c(\d+)$/i;
    return undef;
}

sub __guessResourceType { 
    my $name = shift();
    return 'Appliance'   if  $name =~ /^lab-\d/i;
    return 'Appliance'   if $name =~ /^[abc]\d/i;
    return $FIXED_RESOURCE_TYPES->{$name} if defined $FIXED_RESOURCE_TYPES->{$name};
    return 'DevServer'   if $name =~ /^dev/i;
    return 'PerfNetwork' if $name =~ /^perf.*network/i || $name =~ /system-test/i;
    return 'PerfHost'    if $name =~ /^perf/i || $name =~ /^sun/i;
    return 'RedundPair'  if $name =~ /^redun/i;
    return 'Group'       if $name =~ /^test-resource/i;
    return $1            if $name =~ /^([A-Z]{3})-/;
    return 'Appliance';
}


##############################################################################
## SendRequest - Send a request to the bookit server
##
##############################################################################
sub SendRequest {
    my ($self, $req, %opts) = @_;
    $opts{Verbose} = 0 if !defined $opts{Verbose};

    # Build http request
    #
    my $http = HTTP::Request->new( POST => "$self->{ServerUri}/request/json" );
    $http->header('content-type' => 'application/json');
    $http->content(encode_json($req));

    # Send the http request
    #
    my $res = $self->{Server}->request($http);

    print STDERR "Server error " . ($res->code) . ": ". ($res->message) . "\n" if ($opts{Verbose} && !$res->is_success);
    
    return { Success => $res->is_success,
             Code    => $res->code,
             Message => $res->message,
             Content => $res->is_success ? decode_json($res->decoded_content) : undef,
           };

} # SendRequest #


##############################################################################
## GetUserInfo - Get all of the server information about the current user
##
##############################################################################
sub GetUserInfo { 
    my ($self, %opts) = @_;

    my $res = $self->SendRequest({ type => 'check-login-status', }, %opts);

    return undef if __requestFailed($res);
    return $res->{Content};

} # GetUserInfo #


##############################################################################
## CheckLoginStatus - Check the current user login status
##
##############################################################################
sub CheckLoginStatus { 
    my ($self, %opts) = @_;

    my $res = $self->GetUserInfo(%opts);

    return FAIL if !$res->{loggedIn};
    return OK;

} # CheckLoginStatus #


##############################################################################
## Login - Login to the server
##
##############################################################################
sub Login { 
    my ($self, $user, $pwd, %opts) = @_;

    return OK if $self->CheckLoginStatus(%opts) == OK;

    my $res = $self->SendRequest({ type     => 'login-user',
                                   username => $user,
                                   password => $pwd,
                                 }, %opts);

    return FAIL if __requestFailed($res);
    return $self->CheckLoginStatus();

} # Login #


##############################################################################
## Logout - Logout of the server
##
##############################################################################
sub Logout { 
    my ($self, %opts) = @_;

    return OK if $self->CheckLoginStatus(%opts) == FAIL;

    my $res = $self->SendRequest({ type => 'logout-user', }, %opts);

    return FAIL if __requestFailed($res) || $self->CheckLoginStatus(%opts) == OK;
    return OK;

} # Logout #


##############################################################################
## FindResources - Search for resources matching the query (using the bookit
## server query logic
##
##############################################################################
sub FindResources { 
    my ($self, %opts) = @_;
    $opts{Type} = 'all'  if !defined $opts{Type};
    $opts{Query} = '*'   if !defined $opts{Query};
    $opts{Start} = 'now' if !defined $opts{Start};
    $opts{End} = 'EOD'   if !defined $opts{End};

    my $res = $self->SendRequest({ type            => 'find-resources', 
                                   'resource-type' => $opts{Type},
                                   query           => $opts{Query}, 
                                   'booking-info'  => { start => $opts{Start}, end => $opts{End}, },
                                 }, %opts);

    # The purpose of this internal package is to provide chained methods for converting the 
    # results to more easily digestable formats
    #
    sub __formatRedirector { 
        my ($data, %opts) = @_;
        return $data->__getRaw()          if $opts{GetRaw};
        return $data->__getSummary()      if $opts{GetDetails};
        return $data->__getIpAddresses()  if $opts{GetIpAddresses};
        return $data->__getList();
    }

    { 
        package FindResourcesResult;
        sub new { 
            my ($class, $data) = @_;
            bless($data, $class);
            return $data;
       }

        sub __getRaw { 
            return shift();
        }

        sub __getList { 
            my $self = shift();
            my $res;
            map { push (@{$res}, $self->{$_}->{name}) if defined $self->{$_}->{name}; } keys %{$self};
            return $res;
        }

        sub __getIpAddresses {
            my $self = shift();
            my $res;
            map { push (@{$res}, BookitInterface::__getIpAddress($self->{$_}->{name})) if defined $self->{$_}->{name}; } keys %{$self};
            return $res;
        }

        sub __getSummary { 
            my $self = shift();
            my $res;
            map { $res->{$self->{$_}->{name}} = { 
                Platform     => $self->{$_}->{attrs}->{platform}->{value},
                SerialNumber => $self->{$_}->{serial}, 
                Description  => $self->{$_}->{description},
                Id           => $_,
                Type         => $self->{$_}->{type},
                IsBooked     => $self->{$_}->{booked} || 0,
                Booking      => { User    =>  $self->{$_}->{username}, 
                                  Comment =>  $self->{$_}->{commeent},
                                  Id      =>  $self->{$_}->{booking_id} || $self->{$_}->{'booking-id'},
                                  Start   => $self->{$_}->{start},
                                  End     => $self->{$_}->{end},
                                },
                HasParent    => defined $self->{$_}->{parent_name} && $self->{$_}->{parent_name} =~ /\w/ ? 1 : 0,
                Parent       => $self->{$_}->{parent_name}, 
                IpAddress    => defined $self->{$_}->{attrs}->{ip_addr} && $self->{$_}->{attrs}->{ip_addr}->{value} =~ /\d/ ? 
                                $self->{$_}->{attrs}->{ip_addr}->{value} : BookitInterface::__getIpAddress($self->{$_}->{name}),
                Console      => $self->{$_}->{attrs}->{serial_console}->{value},
                Rack         => $self->{$_}->{attrs}->{rack}->{value},
                OS           => defined $self->{$_}->{attrs}->{OS_Info} && $self->{$_}->{attrs}->{OS_Info}->{value} =~ /\w/ ?
                               $self->{$_}->{attrs}->{OS_Info}->{value} : $self->{$_}->{attrs}->{OS}->{value},
            } if defined $self->{$_}->{name}; } keys %{$self};
            map { $res->{$_}->{Rack} =~ s/\s//msg if defined $res->{$_}->{Rack}; } keys %{$res};
            return $res;
        }

    }

    return new FindResourcesResult(__requestFailed($res) ? undef : $res->{Content});

} # FindResources #


##############################################################################
## Helper utilities for finding resources
##
##############################################################################
sub GetAllResources   { my ($self, %opts) = @_; my $res = $self->FindResources(%opts); return __formatRedirector($res, %opts); }
sub GetAppliances     { my ($self, %opts) = @_; my $res = $self->FindResources(Type => 'Appliance', %opts); return __formatRedirector($res, %opts); }
sub GetRouters        { my ($self, %opts) = @_; my $res = $self->FindResources(Type => 'Appliance', %opts); return __formatRedirector($res, %opts); }
sub GetPerfHosts      { my ($self, %opts) = @_; my $res = $self->FindResources(Type => 'PerfHost', %opts); return __formatRedirector($res, %opts); }
sub GetPerfNetworks   { my ($self, %opts) = @_; my $res = $self->FindResources(Type => 'PerfNetworks', %opts); return __formatRedirector($res, %opts); }
sub GetRedundantPairs { my ($self, %opts) = @_; my $res = $self->FindResources(Type => 'RedundPair', %opts); return __formatRedirector($res, %opts); }
sub GetDevServers     { my ($self, %opts) = @_; my $res = $self->FindResources(Type => 'DevServer', %opts); return __formatRedirector($res, %opts); }


##############################################################################
## FindResourcesWithFlag
##############################################################################
sub FindResourcesWithFlag {
    my ($self, $flag, %opts) = @_;

    my $res = {};

    my $resources = $self->FindResources(%opts);
    foreach my $id (keys %{$resources}) { 
        next if !defined $resources->{$id}->{name};
        next if !defined $resources->{$id}->{attrs}->{flags}->{value};
        $res->{$id} = $resources->{$id} if $resources->{$id}->{attrs}->{flags}->{value} =~ /$flag/;
    }

    return new FindResourcesResult($res);

} # FindResourcesWithFlag #


##############################################################################
## Helper utilities for finding resources with flag
##
##############################################################################
sub GetAppliancesWithFlag     { my ($self, $flag, %opts) = @_; my $res = $self->FindResourcesWithFlag($flag, Type => 'Appliance', %opts); return __formatRedirector($res, %opts); }
sub GetRoutersWithFlag        { my ($self, $flag, %opts) = @_; my $res = $self->FindResourcesWithFlag($flag, Type => 'Appliance', %opts); return __formatRedirector($res, %opts); }
sub GetPerfHostsWithFlag      { my ($self, $flag, %opts) = @_; my $res = $self->FindResourcesWithFlag($flag, Type => 'PerfHost', %opts); return __formatRedirector($res, %opts); }
sub GetPerfNetworksWithFlag   { my ($self, $flag, %opts) = @_; my $res = $self->FindResourcesWithFlag($flag, Type => 'PerfNetworks', %opts); return __formatRedirector($res, %opts); }
sub GetRedundantPairsWithFlag { my ($self, $flag, %opts) = @_; my $res = $self->FindResourcesWithFlag($flag, Type => 'RedundPair', %opts); return __formatRedirector($res, %opts); }
sub GetDevServersWithFlag     { my ($self, $flag, %opts) = @_; my $res = $self->FindResourcesWithFlag($flag, Type => 'DevServer', %opts); return __formatRedirector($res, %opts); }


##############################################################################
## ResourceHasFlag - Returns OK if the supplied router has the supplied
## flag
##
##############################################################################
sub ResourceHasFlag { 
    my ($self, $rsc, $flag, %opts) = @_; 
    
    my $res = __formatRedirector($self->FindResourcesWithFlag($flag, Query => $rsc, %opts), GetList => 1);

    return FAIL if !defined $res || (scalar @{$res} != 1);
    return OK;

} # ResourceHasFlag #


##############################################################################
## Helper utilities for checking a resource for a flag
##
##############################################################################
sub ApplianceHasFlag     { my ($self, $rsc, $flag, %opts) = @_; return $self->ResourceHasFlag($rsc, $flag, Type => 'Appliance', %opts); }
sub RouterHasFlag        { my ($self, $rsc, $flag, %opts) = @_; return $self->ResourceHasFlag($rsc, $flag, Type => 'Appliance', %opts); }
sub PerfHostHasFlag      { my ($self, $rsc, $flag, %opts) = @_; return $self->ResourceHasFlag($rsc, $flag, Type => 'PerfHost', %opts); }
sub PerfNetworkHasFlag   { my ($self, $rsc, $flag, %opts) = @_; return $self->ResourceHasFlag($rsc, $flag, Type => 'PerfNetworks', %opts); }
sub RedundantPairHasFlag { my ($self, $rsc, $flag, %opts) = @_; return $self->ResourceHasFlag($rsc, $flag, Type => 'RedundPair', %opts); }
sub DevServerHasFlag     { my ($self, $rsc, $flag, %opts) = @_; return $self->ResourceHasFlag($rsc, $flag, Type => 'DevServer', %opts); }


##############################################################################
## GetResourceStingStatus - Returns the sting status of a resource (or list 
## resources supplied by reference, returned as hash)
##
##############################################################################
sub GetStingStatus { 
    my ($self, $resource, %opts) = @_;

    if (ref $resource eq '' || ref $resource eq 'SCALAR') { 
        $opts{Type} = __guessResourceType(__normalizeResourceName($resource)) if !defined $opts{Type};
        my $res = $self->SendRequest({ type            => 'get-sting-status', 
                                       'resource-type' => $opts{Type},
                                       name            => __normalizeResourceName($resource),
                                     }, %opts);
        return  __requestFailed($res) ? undef : $res->{Content};
    }

    if (ref $resource eq 'ARRAY') { 
        my $list = {};
        foreach my $rsc (@{$resource}) { 
            $opts{Type} = __guessResourceType(__normalizeResourceName($rsc)) if !defined $opts{Type};
            my $res = $self->SendRequest({ type            => 'get-sting-status', 
                                           'resource-type' => $opts{Type},
                                           name            => __normalizeResourceName($rsc),
                                         }, %opts);
            $list->{$rsc} = __requestFailed($res) ? undef : $res->{Content};
        }
        return $list;
    }

    return undef;

} # GetStingStatus #


##############################################################################
## GetResourceLogs - Returns the logs for a resource (or list
## resources supplied by reference, returned as hash)
##
##############################################################################
sub GetResourceLogs { 
    my ($self, $resource, %opts) = @_;

    if (ref $resource eq '' || ref $resource eq 'SCALAR') {
        $opts{Type} = __guessResourceType(__normalizeResourceName($resource)) if !defined $opts{Type};
        my $res = $self->SendRequest({ type            => 'get-logs-for-resource',
                                       'resource-type' => $opts{Type},
                                       name            => __normalizeResourceName($resource),
                                     }, %opts);
        return  __requestFailed($res) ? undef : $res->{Content};
    }

    if (ref $resource eq 'ARRAY') {
        my $list = {};
        foreach my $rsc (@{$resource}) {
            $opts{Type} = __guessResourceType(__normalizeResourceName($rsc)) if !defined $opts{Type};
            my $res = $self->SendRequest({ type            => 'get-logs-for-resource',
                                           'resource-type' => $opts{Type},
                                           name            => __normalizeResourceName($rsc),
                                         }, %opts);
            $list->{$rsc} = __requestFailed($res) ? undef : $res->{Content};
        }
        return $list;
    }

    return undef;

} # GetResourceLogs #


##############################################################################
## AddResourceLog - Adds a log for a resource
##
##############################################################################
sub AddResourceLog { 
    my ($self, $resource, $log, %opts) = @_;

    $opts{Type} = __guessResourceType(__normalizeResourceName($resource)) if !defined $opts{Type};
    my $res = $self->SendRequest({ type            => 'add-log-for-resource',
                                   'resource-type' => $opts{Type},
                                   name            => __normalizeResourceName($resource),
                                   message         => $log,
                                 }, %opts);

    return FAIL if __requestFailed($res);
    return OK;

} # AddResourceLog # 


##############################################################################
## UpdateLog - Changes the message for a specified log (by id), this 
## should be used sparingly
##
##############################################################################
sub UpdateLog {
    my ($self, $id, $log, %opts) = @_;

    my $res = $self->SendRequest({ type            => 'update-log',
                                   'log-id'        => $id,
                                   message         => $log,
                                 }, %opts);

    return FAIL if __requestFailed($res);
    return OK;

} # UpdateLog #


##############################################################################
## GetResourceEvents - Returns the events for a resource (or list
## resources supplied by reference, returned as hash)
##
##############################################################################
sub GetResourceEvents {
    my ($self, $resource, %opts) = @_;

    if (ref $resource eq '' || ref $resource eq 'SCALAR') {
        $opts{Type} = __guessResourceType(__normalizeResourceName($resource)) if !defined $opts{Type};
        my $res = $self->SendRequest({ type            => 'get-events-for-resource',
                                       'resource-type' => $opts{Type},
                                       name            => __normalizeResourceName($resource),
                                     }, %opts);
        return  __requestFailed($res) ? undef : $res->{Content};
    }

    if (ref $resource eq 'ARRAY') {
        my $list = {};
        foreach my $rsc (@{$resource}) {
            $opts{Type} = __guessResourceType(__normalizeResourceName($rsc)) if !defined $opts{Type};
            my $res = $self->SendRequest({ type            => 'get-events-for-resource',
                                           'resource-type' => $opts{Type},
                                           name            => __normalizeResourceName($rsc),
                                         }, %opts);
            $list->{$rsc} = __requestFailed($res) ? undef : $res->{Content};
        }
        return $list;
    }

    return undef;

} # GetResourceEvents #



1;

