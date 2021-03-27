package Solace::Sm::Router;

use strict;
use warnings;
use Data::Dumper;
use Sys::Hostname;

use Solace::Sm::Env;

## Private class data
#####################

## Constructor
##############
sub new($$$$) {
  my $class = shift();

  my $self = {};
  $self->{num} = shift();
  $self->{host} = shift();
  $self->{mode} = shift();

  my $solsmDir = shift();
  if (!$solsmDir) {
      $solsmDir = $Solace::Sm::Env::cvswd;
  }

  ## Private class data access.

  bless($self, $class);
  $self->init($solsmDir);

  return $self;
}

## Object methods
#################

sub isDev() {
  die("Router::isDev() invoked");
}

sub getName() {
  my $self = shift();
  return $self->{num} . ":" . $self->{host};
}

sub getHost() {
  my $self = shift();
  return $self->{host};
}

sub getNbrName() {
  my $self = shift();
  if ($self->isDev()) {
    return $self->getName();
  }
    return $self->getHost();
}

sub getMode() {
  my $self = shift();
  return $self->{mode};
}

sub getDir() {
  die("Router::getDir() invoked");
}

sub getNum() {
  my $self = shift();
  return $self->{num};
}

## If a child name is provided, look for it as a child of the
## solacedaemon process.  Otherwise, return the solacedaemon process
## pid.
sub getPid($) {
  my $self = shift();
  my $child = shift();

  my $pid;
  if ($self->isDev()) {
    ## For dev simulators we keep a link to the solacedaemon.pid in a
    ## common place in our HOME dir so that collisions between router
    ## dirs can be detected.
    my $homePidFile = $ENV{HOME} . "/.sm/solacedaemon.pid." . $self->getNum();
    if (-r $homePidFile) {
      $pid = `cat $homePidFile`;
    }
  }
  else {
    $pid = $self->getDirFile("solacedaemon.pid");
  }

  if ($pid && $child) {
    ## Exact match with $pid as parent.
    chomp($pid);
    $pid = $self->runOnHost("/usr/bin/pgrep -P$pid -x $child");
  }
  if ($pid) {
    chomp($pid);
    return $pid;
  }
  return undef();
}

sub getMgmtIp() {
  my $self = shift();

  ## Avoid loopback address for ourselves.
  my $host = $self->getHost();
  if ($host eq "localhost") {
    $host = hostname();
  }

  my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($host);
  my ($a,$b,$c,$d) = unpack('C4', $addrs[0]);
  return "$a." . "$b." . "$c." . "$d";
}

sub getMsgBbIp() {
  die("Router::getMsgBbIp() invoked");
}


sub getPort($) {
  my $self = shift();
  my $type = shift();
  my $port = $self->{ports}{$type};
  if (!$port) {
    die("Unknown port-type '$type'");
  }
  return $port;
}

sub init($$) {
  my $self = shift();
  my $solsmDir = shift();

  ## Create any needed directories.
  $self->doInitDirs($solsmDir);

  ## Adjust opMode to that of the db if it was not specified.
  ##
  if ($self->{mode} eq "unspecified") {
      $self->{mode} = $self->getDbMode();
  }

  ## If for some reason mode still has not been determined, perhaps
  ## because it was unspecified and there is no existing db, default
  ## to SolTR as this is what is likely most useful.
  ##
  if (!$self->{mode}) {
      $self->{mode} = "soltr";
  }

  $self->doInit();

}

sub doInitDirs($) {
}

sub doInit() {
  die("Router::doInit() invoked");
}

## Get the operation mode in our existing db.  Will an empty string if
## this cannot be determined.
##
sub getDbMode() {
  my $self = shift();

  ## TODO: only support dev routers at the moment.
  if (!$self->isDev()) {
      return "";
  }

  my $soldbsp = $Solace::Sm::Env::soldbsp;
  my $dir = $self->getDir();
  my $cvswd = $Solace::Sm::Env::cvswd;
  my $ldpath = $Solace::Sm::Env::ldpath;
  my $env = "CVSWD=$cvswd LD_LIBRARY_PATH=$ldpath";
  my $cmd = "$env $soldbsp -d $dir operatingMode";
  my $modeNum = $self->runOnHost($cmd);
  chomp($modeNum);

  my $dbMode = "";
  if ($modeNum) {
      $dbMode = $Solace::Sm::Env::numToOpMode{$modeNum};
      chomp($dbMode);
  }
  return $dbMode;
}


## Run the given command on the host for this router.  The output of
## the command is returned, and the status of the command is captured
## in $?.
sub runOnHost($) {
  die("Router::runOnHost() invoked");
}

## Replace the current executable with the given command on the host
## for this router.  Never returns.
sub execOnHost($) {
  die("Router::execOnHost() invoked");
}

## Return the contents of the given file (in our directory) as a
## string.  If the file does not exists, an empty string should be
## returned.
sub getDirFile($) {
  my $self = shift();
  my $file = $self->getDir() . "/" . shift();
  return $self->runOnHost("test -r $file && cat $file");
}

## Remove the the given file (in our directory).
sub rmDirFile($) {
  my $self = shift();
  my $file = $self->getDir() . "/" . shift();
  return $self->runOnHost("/bin/rm -f $file");
}

## Link to a given file (in our directory).
sub lnDirFile($$) {
  die("Router::copyFileToDir() invoked");
}

## Copy the given file to a location relative to our directory.
sub copyFileToDir($$) {
  die("Router::copyFileToDir() invoked");
}

sub getSempRpcXsd($) {
  my $self = shift();
  my $mode = $self->{mode};
  my $objdir = $Solace::Sm::Env::objdir;

  return "$objdir/etc/semp-rpc-" . $mode . ".xsd";
}

sub getSempRpcReplyXsd($) {
  my $self = shift();
  my $mode = $self->{mode};
  my $cvswd = $Solace::Sm::Env::cvswd;

  return "$cvswd/solcbr/schema/semp-rpc-reply-" . $mode . ".xsd";
}

sub getSempRpcVersion($) {
  my $self = shift();

  my $xsd = $self->getSempRpcXsd();

  if ($xsd) {
    my $fd;
    open($fd, "<", $xsd) || return undef;
    while (my $line = <$fd>) {
      if ($line =~ /name="semp-version".*?fixed="\w+\/([\w\d_\-\.]+)/) {
        return $1;
      }
    }
  }

  return undef;
}

## Class Methods
################

## Bimodal Methods (class or object)
####################################

## Miscellaneous helper functions
################################

1;


