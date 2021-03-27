#############################################################################
##
## HTML::Simple
##
## This module will try to make it as simple as possible to produce HTML
##
#############################################################################

package HTML::Simple;

use strict;
use warnings;
use Data::Dumper;
use Carp;

use HTML::Simple::Table;
use HTML::Simple::Style;
use HTML::Simple::GenericElement;
use HTML::Simple::Container;
use HTML::Simple::Skins;


my %headElems = (title => 1);

# new - create a new object to interact with a specific router
#
# Parameters:
#   o title     - Title for the html

sub new {
  my $class = shift;
  my %args  = @_;

  # map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{router};

  my %self = (title          => defined($args{title})      ? $args{title}      : undef,
              head           => new HTML::Simple::Container(type => "head"),
              body           => new HTML::Simple::Container(type => "body"),
              skin           => new HTML::Simple::Skins(skin => $args{skin}),
      );

  bless(\%self, $class);

  if (defined($self{title})) {
    my $s = \%self;
    $s->title($self{title});
  }

  return \%self;

}


# serialize
#
# Combine all the current chunks of html into a single blob of html and
# return it
sub serialize {
  my $self = shift;
  
  my $html = '<!DOCTYPE html>';

  $html   .= "<html>\n";
  
  $html   .= $self->{head}->serialize();
  $html   .= $self->{body}->serialize();

  $html   .= "</html>\n";

  return $html;

}



# css
#
# Add some CSS to the page
#
sub css {
  my ($self, $css) = @_;

  if (!defined($self->{style})) {
    my $style = $self->{head}->style(css => [$css]);
    $self->{style} = $style;
  }
  else {
    $self->{style}->append(css => [$css]);
  }

  return $self->{style};

}


# head
#
# return the head object
sub head {
  my $self = shift;

  return $self->{head};
}

# body
#
# return the body object
sub body {
  my $self = shift;

  return $self->{body};
}


# applySkin - Get some CSS from the specified skin and add it 
sub applySkin {
  my $self = shift;

  my $css = $self->{skin}->getCss(@_);
  $self->css($css);

}


# Catch all for some simple adds - always assume they are going to 
# the body element.  To add to the head, you must explicitely grab
# the head object with head()
sub AUTOLOAD {
  my ($self, $value, $attrs) = @_;
  our $AUTOLOAD;

  my ($element) = ($AUTOLOAD =~ /::(\w*)$/);

  if ($headElems{$element}) {
    eval("return \$self->{head}->$element(\$value, \$attrs);");
  }
  else {
    eval("return \$self->{body}->$element(\$value, \$attrs);");
  }

}

1;
