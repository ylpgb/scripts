#############################################################################
##
## HTML::Simple::HTML
##
## This module will add a simple element to the simple HTML object with the
## specified element name
##
#############################################################################

package HTML::Simple::HTML;

use strict;
use warnings;
use Data::Dumper;
use Carp;


# new - create a new object to interact with a specific router
#
# Parameters:
#   o html text
#

sub new {
  my $class = shift;
  my $html  = $_[0];

  my %self = (html => $html);

  bless(\%self, $class);

  return \%self;

}


# serialize - convert the table into actual HTML

sub serialize {
  my ($self) = @_;

  return $self->{html};

}

1;
