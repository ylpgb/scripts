package Solace::Sm::Cmd::PubSub;

use warnings;
use base Solace::Sm::Cmd::Base;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  my $type = $self->getType();

  for my $i ($self->{args}{min}..$self->{args}{max}) {
    my $psName = $self->{args}{prefix} . $i;
    my $status;
    if (!$self->{args}{remove}) {
      $self->debug("Adding $type $psName to router " . $rtr->getName);
      $status = $self->sempRpc($rtr, "<$type><name>$psName</name></$type>");
    }
    else {
      $self->debug("Removing $type $psName from router " . $rtr->getName);
      $status = $self->sempRpc($rtr, "<no><$type><name>$psName</name></$type></no>");
    }
    if ($status !~/^200/) {
      $self->error($status);
    }
  }
}

sub getType() {
  ## Override this.
  die("PubSub::getType() invoked");
}

1;


