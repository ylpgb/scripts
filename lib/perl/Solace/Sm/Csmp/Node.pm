package Solace::Sm::Csmp::Node;

use strict;
use warnings;

## Private class data
#####################

## Constructor
##############
sub new($$) {
  my $class = shift();

  my $self = {};
  $self->{rtr} = shift();
  $self->{state} = shift();

  ## Private class data access.

  bless($self, $class);
  return $self;
}

## Object methods
#################

sub getRtr() {
  my $self = shift();
  return $self->{rtr};
}

sub getState() {
  my $self = shift();
  return $self->{state};
}

1;


