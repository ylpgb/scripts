#############################################################################
##
## HTML::Simple::Style
##
## This module will add a style to the simple HTML object
##
#############################################################################

package HTML::Simple::Style;

use strict;
use warnings;
use Data::Dumper;
use Carp;


# new - create a new object to interact with a specific router
#
# Parameters:
#   o css         - CSS to add - this is an array of strings
#

sub new {
  my $class = shift;
  my %args  = @_;

  # map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{};
  
  my %defaults = (css    => [],
  );

  my %self = %args;

  foreach my $key (keys(%defaults)) {
    if (!defined($self{$key})) {
      $self{$key} = $defaults{$key};
    }
  }

  bless(\%self, $class);

  return \%self;

}


# append - add more CSS

sub append {
  my ($self, %args) = @_;

  if (ref($args{css}) eq "ARRAY") {
    push(@{$self->{css}}, @{$args{css}}); 
  }
  else {
    push(@{$self->{css}}, $args{css}); 
  }
}


# serialize - convert the table into actual HTML

sub serialize {
  my ($self) = @_;

  my $html;

  if (@{$self->{css}}) {
    $html .= "<style type='text/css'>\n";
    $html .= "<!--\n";
    $html .= join("\n", @{$self->{css}});
    $html .= "--></style>\n";
  }

  return $html;

}



1;
