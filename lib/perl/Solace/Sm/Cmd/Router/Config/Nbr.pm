package Solace::Sm::Cmd::Router::Config::Nbr;

use warnings;
use base Solace::Sm::Cmd::Base;

sub doRun() {
  my $self = shift();
  my @rtrs = $self->getRouters();

  if (@rtrs < 2) {
    $self->fatal("The nbr command can only be used with >1 routers");
  }

  ## Form a list of neighbor pairs.  May pair the given list of
  ## routers in different ways depending on the "topology" option.
  my $top = $self->{args}{topology};
  my @pairs = ();
  if ($top eq "chain" || $top eq "loop") {
    ## Every router is paired with its adjacent routers.
    for (my $i = 0; $i < @rtrs-1; $i++) {
      push(@pairs, [$rtrs[$i], $rtrs[$i+1]]);
    }
    if ($top eq "loop") {
      ## Connect head to tail.
      push(@pairs, [$rtrs[@rtrs-1], $rtrs[0]])
    }
  }
  elsif ($top eq "mesh") {
    ## Every router is paired with every other router.
    for (my $i = 0; $i < @rtrs; $i++) {
      for (my $j= $i+1; $j < @rtrs; $j++) {
        push(@pairs, [$rtrs[$i], $rtrs[$j]]);
      }
    }
  }
  elsif ($top eq "hub") {
    ## First router is paired with every other router.
    for (my $i = 1; $i < @rtrs; $i++) {
      push(@pairs, [$rtrs[0], $rtrs[$i]]);
    }
  }
  else {
    $self->fatal("Invalid topology value of $top");
  }

  my $cons = $self->{args}{connections};
  foreach my $pair (@pairs) {
    my ($r1, $r2) = @$pair;

    if (!$self->{args}{remove}) {
      if ($self->{args}{direction} ne "oneway") {
        $self->peer($r2, $r1, $cons);
      }
      if ($self->{args}{direction} ne "otherway") {
        $self->peer($r1, $r2, $cons);
      }
    }
    else {
      if ($self->{args}{direction} ne "oneway") {
        $self->unpeer($r2, $r1);
      }
      if ($self->{args}{direction} ne "otherway") {
        $self->unpeer($r1, $r2);
      }
    }
  }
}

## Make a pair of routers peers (neighbors) in one direction.
##
sub peer($$$) {
  my $self = shift();
  my ($r1, $r2, $cons) = @_;
  my $ip2 = $r2->getMsgBbIp();
  my $tport2 = $r2->getPort("tcp");
  my $name2 = $r2->getNbrName();
  $self->info("Making router ", $r2->getName(), 
	      " neighbor of router ", $r1->getName(), "...\n");
  my $status;
  if ($r1->getMode() eq "solos") {
    $status = $self->sempRpc($r1, "<routing><cspf><create><neighbor><ip-addr>$ip2</ip-addr><port>$tport2</port><num-con>$cons</num-con></neighbor></create></cspf></routing>");
  }
  else {
    $status = $self->sempRpc($r1, "<routing><cspf><create><neighbor><physical-router-name>$name2</physical-router-name><connect-via>$ip2:$tport2</connect-via><num-con>$cons</num-con></neighbor></create></cspf></routing>");
  }
  if ($status !~/^200/) {
    $self->error("$status");
  }
}
sub unpeer($$) {
  my $self = shift();
  my ($r1, $r2) = @_;
  my $ip2 = $r2->getMsgBbIp();
  my $tport2 = $r2->getPort("tcp");
  my $name2 = $r2->getNbrName();
  $self->info("Removing router ", $r2->getName(), 
	      " neighbor of router ", $r1->getName(), "...\n");
  my $status;
  if ($r1->getMode() eq "solos") {
    $status = $self->sempRpc($r1, "<routing><cspf><no><neighbor><ip-addr>$ip2</ip-addr><port>$tport2</port></neighbor></no></cspf></routing>");
  }
  else {
    $status = $self->sempRpc($r1, "<routing><cspf><no><neighbor><physical-router-name>$name2</physical-router-name></neighbor></no></cspf></routing>");
  }

  if ($status !~/^200/) {
    $self->error("$status");
  }
}

1;


