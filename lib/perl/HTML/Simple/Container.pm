#############################################################################
##
## HTML::Simple::Container
##
## This module is able to contain other HTML::Simple objects.  It is used
## by the head, body, div, span, td and th elements.
##
#############################################################################

package HTML::Simple::Container;

use strict;
use warnings;
use Data::Dumper;
use Carp;

use HTML::Simple::Table;
use HTML::Simple::GenericElement;
use HTML::Simple::HTML;

# new - create a new object to interact with a specific router
#
# Parameters:
#   o tbd


sub new {
  my $class = shift;
  my %args  = @_;

  map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{type};
  # croak "Unsupported container type: $args{type}" if (!grep(/^$args{type}$/, (qw{div span td th body head})));
  
  if ($args{attrs} && ref($args{attrs}) eq "HASH") {
    my @attrs;
    foreach my $k (keys(%{$args{attrs}})) {
      if (!defined($args{attrs}->{$k})) {
        warn("Missing value for attribute: $k\n");
      }
      push(@attrs, "$k='$args{attrs}->{$k}'");
    }
    $args{attrs} = \@attrs;
  }

  $args{attrs} = [$args{attrs}] if defined($args{attrs}) && (ref($args{attrs}) ne "ARRAY");

  my %defaults = (
    attrs    => [],
    newline  => 1,
  );

  my %self = %args;

  foreach my $key (keys(%defaults)) {
    if (!defined($self{$key})) {
      $self{$key} = $defaults{$key};
    }
  }

  if ($self{type} eq "span" || $self{type} eq "div" || $self{type} eq "a") {
    $self{newline} = 0;
  }

  $self{chunks} = [];
  $self{style}  = undef;

  bless(\%self, $class);

  if (defined($args{value}) &&
      ref $args{value} eq "") {
    (\%self)->html($args{value});
  }

  return \%self;

}


# serialize
#
# Combine all the current chunks of html into a single blob of html and
# return it
sub serialize {
  my $self = shift;
  
  my $html = "<$self->{type}";
  $html .= " @{$self->{attrs}}" if @{$self->{attrs}};
  $html .= ">";
  map {$html .= $_->serialize(); } @{$self->{chunks}};
  $html .= "</$self->{type}>";
  $html .= "\n" if $self->{newline};
  
  return $html;

}


# table
#
# Add a new table to the page
#
sub _table {
  my ($self, %args) = @_;

  my $table;
  if ($args{rows}) {
    $table = new HTML::Simple::Table(%args);
  }
  else {
    $table = new HTML::Simple::Container(type => $args{element}, 
                                         value => $args{value},
                                         attrs => $args{attrs});
  }
  
  push(@{$self->{chunks}}, $table);
  return $table;

}

# html
# 
# Add a chunk of html
#
sub html {
  my ($self, $html) = @_;
  
  my $chunk = new HTML::Simple::HTML($html);

  push(@{$self->{chunks}}, $chunk);

  return $chunk;

}

# style
#
# Add CSS to the container
#
sub style {
  my ($self, %args) = @_;

  if (defined($self->{style})) {
    $self->{style}->append(%args);
  }
  else {
    my $style = new HTML::Simple::Style(%args);
    push(@{$self->{chunks}}, $style);
    $self->{style} = $style;
  }

  return $self->{style};

}


# Catch all for some simple adds
sub AUTOLOAD {
  my ($self, $value, $attrs) = @_;
  our $AUTOLOAD;

  my @elements   = qw{title p i b div span br h1 h2 h3 h4 h5 h6 h7 h8 input textarea select option ul ol li a form script img table tr th td thead tfoot code pre link hr};
  my @containers = qw{div span select b i p input a ul ol li form h1 h2 h3 h4 h5 h6 h7 h8 table tr th td thead tfoot code pre};

  if (grep {"HTML::Simple::Container::$_" eq $AUTOLOAD} @elements) {
    my ($element) = ($AUTOLOAD =~ /::(\w*)$/);
    
    my $obj;
    if (grep {$_ eq $element} @containers) {
      if ($element eq "table") {
        my ($s, %args) = @_;
        if (defined($args{rows})) {
          return $self->_table(%args);
        }
      }

      $obj = new HTML::Simple::Container(type => $element, 
                                         value => $value,
                                         attrs => $attrs);
    }
    else {
      $obj = new HTML::Simple::GenericElement(name => $element,
                                              value => $value,
                                              attrs => $attrs);
    }
    
    push(@{$self->{chunks}}, $obj);

    return $obj;
  }
  elsif ($AUTOLOAD =~ /DESTROY/) {
  }
  else {
    croak("Undefined method called: $AUTOLOAD");
  }

}

1;
