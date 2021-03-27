package Solace::Sm::Cmd::Base;

use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use Sys::Hostname;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

use Solace::Sm::Dev::Router;
use Solace::Sm::Prod::Router;

## Private class data
#####################

## Callbacks.  A hash of function references to call.
my %callbacks;

## Constructor
##############
sub new($) {
  my $class = shift();
  my $hashref = shift();

  my $self = {};
  $self->{class} = $class;
  $self->{args} = $hashref;

  ## A command can provide a means to turn off validation.  But if it
  ## doesn't them make sure to turn it on.
  if (!defined($self->{args}{validate})) {
    $self->{args}{validate} = 1;
  }

  ## Private class data access.
  $self->{_callbacks} = \%callbacks;
  bless($self, $class);
  return $self;
}

## Object methods
#################

sub run() {
  my $self = shift();
  $self->debug("Running the $self->{class} command with arguments:");
  $self->debug(Dumper $self->{args});
  return $self->doRun($self);
}

sub doRun() {
  ## This may be overridden if needed.
  ##
  my $self = shift();
  my @rtrs = $self->getRouters();

  foreach my $rtr (@rtrs) {
    $self->debug("doRunSingle() for router " . $rtr->getName());
    $self->doRunSingle($rtr);
  }
  return @rtrs;
}

sub doRunSingle($) {
  ## This should be overridden by the individual command.
  ##
  die("Base::doRun() invoked");
}

sub getRouters() {
  my $self = shift();
  my @nums = ();
  my $ranges_ref = $self->{args}{router_number_range};
  foreach my $range (@$ranges_ref) {
    push(@nums, num_range($range));
  }

  ## Determine our router number to host mapping.  Default is our
  ## current host.
  my %hostMap;
  foreach my $num (@nums) {
    $hostMap{$num} = hostname();
  }
  my @rtrHosts = split(/,/, $self->{args}{router_hosts});
  foreach my $rtrHost (@rtrHosts) {
    ## If a : is present presume it separates the router number and
    ## that router's hostname.  Otherwise assume the hostname for
    ## router 0.
    my ($k,$v) = (0, hostname());
    if (index($rtrHost, ":") >= 0) {
      ($k,$v) = split(/:/, $rtrHost);
    }
    else {
      $v = $rtrHost;
    }
    $hostMap{$k} = $v;
  }

  my $mode = $self->{args}{mode};
  my $solsmDir = $self->{args}{sm_dir};

  my @rtrs;
  foreach my $num (@nums) {
    my $host = $hostMap{$num};
    if ($host =~ m/^dev/ || $host eq "localhost") {
      push(@rtrs, Solace::Sm::Dev::Router->new(
	       $num, $hostMap{$num}, $mode, $solsmDir));
    }
    else {
      push(@rtrs, Solace::Sm::Prod::Router->new(
	       $num, $hostMap{$num}, $mode, $solsmDir));
    }
  }
  return @rtrs;
}

sub log($$$) {
  my $self = shift();
  my $level = shift();
  if ($self->{_callbacks}{$level}) {
    $self->{_callbacks}{$level}(shift(), 0);
  }
  else {
    die("Missing $level log callback");
  }
}


sub fatal($$) {
  my $self = shift();
  return $self->log("fatal", @_);
}

sub error($$) {
  my $self = shift();
  return $self->log("error", @_);
}

sub warn($$) {
  my $self = shift();
  return $self->log("warn", @_);
}

sub info($$) {
  my $self = shift();
  return $self->log("info", @_);
}

sub debug($$) {
  my $self = shift();
  return $self->log("debug", @_);
}

sub msg($$) {
  my $self = shift();
  return $self->log("msg", @_);
}

## Send a SEMP message to a given router.  Returns the response code
## status line as a string, and the xml reply as a string.
##
sub sempRpcReply($$) {
  my $self = shift();
  my $rtr = shift();
  my $msg = shift();

  my $uri = "http://" . $rtr->getMgmtIp() . ":" . $rtr->getPort('http') . "/SEMP";
  my $req = HTTP::Request->new(POST => "$uri");

  my $user = $self->{args}{semp_user};
  my $pw = $self->{args}{semp_password};

  my $verRoot = $rtr->getMode();
  my $ver = $rtr->getSempRpcVersion();

  if (!defined($ver)) {
    if ($rtr->getMode() eq "tma") {
      $ver = "1_1";
    }
    elsif ($rtr->getMode() eq "solos") {
      $ver = "5_4";
    }
    elsif ($rtr->getMode() eq "soltr") {
      $ver = "5_5";
    }
    else {
      $ver = "0.0";
    }
  }

  if (defined($ENV{SM_SEMP_VER})) {
    $ver = $ENV{SM_SEMP_VER};
  }

  my $verAttrib = "$verRoot/$ver";

  $req->authorization_basic("$user", "$pw");
  $req->content("<rpc semp-version='" . $verAttrib . "'>" . $msg . "</rpc>");
  
  if ($self->{args}{validate}) {
    my $err = validate($req->content(), $rtr->getSempRpcXsd());
    if ($err) {
      $self->fatal($err);
    }
  }

  my $ua = LWP::UserAgent->new(timeout => 10);

  $self->debug("Sending SEMP rpc:");
  $self->debug($req->as_string());

  my $resp = $ua->request($req);

  $self->debug("Received SEMP rpc-reply:");
  $self->debug($resp->as_string());

  if ($self->{args}{validate} && $resp->status_line() =~ /^200/) {
    my $err = validate($resp->content(), $rtr->getSempRpcReplyXsd());
    if ($err) {
      $self->fatal($err);
    }
  }

  return ($resp->status_line(), $resp->content());
}

## Send a SEMP message to a given router.  Returns response code
## status line as a string.
##
sub sempRpc($$) {
  my $self = shift();
  my $rtr = shift();
  my $msg = shift();
  my ($status, $xml) = $self->sempRpcReply($rtr, $msg);
  return $status;
}

## Class Methods
################

sub installCallbacks {
  my $class = shift();
  my $hashref = shift();
  foreach my $cb (keys(%$hashref)) {
    $callbacks{$cb} = $hashref->{$cb};
  }
}

## Bimodal Methods (class or object)
####################################

## Miscellaneous helper functions
################################

sub min($$) {
  return $_[0] > $_[1] ? $_[1] : $_[0];
}
sub max($$) {
  return $_[1] > $_[0] ? $_[1] : $_[0];
}

## Convert string of the form "n" or "n-m" to an list of numbers.
##
sub num_range($) {
  my ($range) = @_;
  my @nums = ();
  if ($range =~ m/^(\d+)$/) {
    push(@nums, $1);
  }
  elsif ($range =~ m/^(\d+)-(\d+)$/) {
    ## For fun, preserve the order, up or down.
    ##
    foreach my $n (min($1,$2)..max($1,$2)) {
      push(@nums, $n);
    }
    if ($1 > $2) {
      @nums = reverse(@nums);
    }
  }
  return @nums;
}

## Validate an XML string against an XML schema.
##
sub validate($$) {
  my ($xml, $xsl_file) = @_;

  my ($fh1, $fn1) = File::Temp::tempfile();
  my ($fh2, $fn2) = File::Temp::tempfile();
  print $fh1 $xml;
  if (system("xmllint --schema $xsl_file --noout $fn1 >& $fn2")) {
      my $msg = "Schema validation against: $xsl_file failed:\n\n" . `cat $fn2`;
    return("$msg");
  }
  else {
    unlink($fn1);
    unlink($fn2);
  }
  return "";
}

1;


