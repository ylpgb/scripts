package Solace::Sm::Cmd::Router::Config::Rv::Uplink;

use warnings;
use base Solace::Sm::Cmd::Base;

sub doRun() {
  my $self = shift();
  my @rtrs = $self->getRouters();

  if (@rtrs < 2) {
    $self->fatal("The uplink command can only be used with >1 routers");
  }

  ## Form a list of uplink pairs, root first.  May pair the given list
  ## of routers in different ways depending on the "topology" option.
  my $top = $self->{args}{topology};
  my @pairs = ();
  if ($top eq "chain") {
    ## Every router is uplinked with its preceeding router.
    for (my $i = 1; $i < @rtrs; $i++) {
      push(@pairs, [$rtrs[$i-1], $rtrs[$i]]);
    }
  }
  elsif ($top eq "fan") {
    ## First router is uplink of every other router.
    for (my $i = 1; $i < @rtrs; $i++) {
      push(@pairs, [$rtrs[0], $rtrs[$i]]);
    }
  }
  else {
    $self->fatal("Invalid topology value of $top");
  }

  foreach my $pair (@pairs) {
    my ($r1, $r2) = @$pair;

    if (!$self->{args}{remove}) {
      $self->uplink($r1, $r2, $cons);
    }
    else {
      $self->unuplink($r1, $r2);
    }
  }
}

## Make a pair of routers uplinked.
##
sub uplink($$$) {
  my $self = shift();
  my ($r1, $r2, $cons) = @_;

  my $ipAndPort = $r1->getMsgBbIp() . ":" . $r1->getPort("tcp");

  $self->info("Making router ", $r1->getName(), 
	      " uplink of router ", $r2->getName(), "...\n");

  my $status;
  $status = $self->sempRpc($r2, "<rv><shutdown/></rv>");
  if ($status !~/^200/) {
    $self->error("Cannot shutdown Rv: $status");
  }

  $status = $self->sempRpc($r2, "<rv><uplink><ip-and-port>$ipAndPort</ip-and-port></uplink></rv>");
  if ($status !~/^200/) {
    $self->error("Cannot set uplink: $status");
  }

  $status = $self->sempRpc($r2, "<rv><no><shutdown/></no></rv>");
  if ($status !~/^200/) {
    $self->error("Cannot enable Rv: $status");
  }
}

sub unuplink($$) {
  my $self = shift();
  $self->fatal("Removal of uplink not supported");
}

1;


