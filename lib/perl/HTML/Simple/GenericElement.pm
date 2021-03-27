#############################################################################
##
## HTML::Simple::GenericElement
##
## This module will add a simple element to the simple HTML object with the
## specified element name
##
#############################################################################

package HTML::Simple::GenericElement;

use strict;
use warnings;
use Data::Dumper;
use Carp;


# new - create a new object to interact with a specific router
#
# Parameters:
#   o name      - name of the element
#   o attrs     - hash of attributes to add
#   o value     - value of the element
#

sub new {
  my $class = shift;
  my %args  = @_;

  map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{name value};
  
  my %defaults = (attrs    => [],
                  newline  => 1,
  );

  if ($args{attrs} && ref($args{attrs}) eq "HASH") {
    my @attrs;
    foreach my $k (keys(%{$args{attrs}})) {
      push(@attrs, "$k='$args{attrs}->{$k}'");
    }
    $args{attrs} = \@attrs;
  }

  my %self = %args;

  foreach my $key (keys(%defaults)) {
    if (!defined($self{$key})) {
      $self{$key} = $defaults{$key};
    }
  }

  bless(\%self, $class);

  return \%self;

}


# serialize - convert the table into actual HTML

sub serialize {
  my ($self) = @_;

  my $html;

  # Need to special case <br> since it seems that Chrome (at least) doesn't
  # like <br></br> - treats it like two <br>s
  
  if ($self->{name} eq "br") {
    return "<br>\n";
  }

  $html .= "<$self->{name}";
  $html .= " @{$self->{attrs}}" if @{$self->{attrs}};
  $html .= ">";

  if (ref($self->{value}) eq "HTML::Simple::Container") {
    $html .= $self->{value}->serialize();
  }
  elsif (defined($self->{value})) {
    $html .= "$self->{value}" ;
  }
  $html .= "</$self->{name}>";
  $html .= "\n" if $self->{newline};

  return $html;

}

sub setValue {
  my ($self, $value, $attrs) = @_;

  $self->{value} = $value;
  $self->{attrs} = $attrs;

}

1;
