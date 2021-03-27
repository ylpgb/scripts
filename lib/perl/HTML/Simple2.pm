#############################################################################
##
## HTML::Simple2
##
## This module will try to make it as simple as possible to produce HTML
##
#############################################################################

package HTML::Simple2;

use strict;
use warnings;
use Data::Dumper;
use Carp;


# new - create a new object to interact with a specific router
#
# Parameters:
#   o title     - Title for the html

sub new {
  my ($class, $args) = @_;

  $args->{type} ||= "page";

  my %self = (
    type    => $args->{type},
    content => $args->{content} || "",
    attrs   => $args->{attrs},
    parent  => $args->{parent}
  );

  bless(\%self, $class);

  if ($args->{type} eq "page") {
    my $s = \%self;
    $s->{head} = $s->head();
    $s->{body} = $s->body();
    if ($args->{title}) {
      $s->{head}->title($args->{title});
    }
  }
  
  return \%self;

}


# serialize
#
# Combine all the current chunks of html into a single blob of html and
# return it
sub serialize {
  my ($self, $args) = @_;

  if ($args->{text}) {
    return $self->serializeAsText($args);
  }

  my $html = "";
  if ($self->{type} eq "page") {
    $html = "<!DOCTYPE html>\n";
    $html   .= "<html>\n";
    $html   .= $self->{head}->serialize();
    $html   .= "\n";
    $html   .= $self->{body}->serialize();
    $html   .= "\n</html>\n";
  }
  else {
    # Just serialize this node and all children
    $html .= "<$self->{type}";
    if ($self->{attrs}) {
      foreach my $key (keys(%{$self->{attrs}})) {
        $html .= " $key=\"$self->{attrs}{$key}\"";
      }
    }
    $html .= ">$self->{content}";

    if ($self->{children}) {
      foreach my $child (@{$self->{children}}) {
        $html .= $child->serialize($args);
      }
    }
    $html   .= "</$self->{type}>";
  }

  return $html;

}


# serialize
#
# Combine all the current chunks of html into a single blob of html and
# return it
sub serializeAsText {
  my ($self, $args) = @_;

  my %skipElms = (select => 1,
                  style => 1,
  );
  my %blockElms = (div => 1,
                   p   => 1
  );
  my %specialElms = (table => \&serializeAsTextTable, 
                     hr    => \&serializeAsTextHr,
  );

  my $text = "";

  return "" if ($skipElms{$self->{type}});

  if ($specialElms{$self->{type}}) {
    return &{$specialElms{$self->{type}}}($self, $args);
  }

  if ($blockElms{$self->{type}}) {
    $text .= "\n";
  }

  $text .= "$self->{content}" if defined($self->{content});

  if ($self->{children}) {
    foreach my $child (@{$self->{children}}) {
      $text .= $child->serializeAsText($args);
    }
  }

  if ($text ne "\n" && $blockElms{$self->{type}}) {
    $text .= "\n";
  }

  return $text;

}


sub serializeAsTextHr {
  return "\n" . ("-" x 78) . "\n";
}

sub serializeAsTextTable {
  my ($self, $args) = @_;
  my $text = "\n";

  if ($self->{children}) {
    my @rows;
    foreach my $child (@{$self->{children}}) {
      if (lc($child->{type}) eq "tr") {
        push(@rows, $child->getCellsAsText());
      }
    }

    my @colWidth;
    my @rowHeight;
    my @cellText;
    my $j = 0;
    foreach my $row (@rows) {
      my $i = 0;
      foreach my $cell (@{$row}) {
        my @lines = split(/\n/, $cell);
        $cellText[$j][$i] = \@lines;
        if (!defined($rowHeight[$j]) || scalar(@lines) > $rowHeight[$j]) {
          $rowHeight[$j] = scalar(@lines);
        }
        foreach my $line (@lines) {
          if (!defined($colWidth[$i]) || length($line) > $colWidth[$i]) {
            $colWidth[$i] = length($line);
          }
        }
        $i++;
      }
      $j++;
    }
    sub drawSeparator {
      my ($loc, $cw) = @_;
      my $delim;
      if ($loc eq "top") {
        $delim = ".";
      }
      elsif ($loc =~ /^bot/i) {
        $delim = "'";
      }
      else {
        $delim = "|";
      }
      my $text .= "$delim";
      foreach my $col (@{$cw}) {
        $text .= ("-" x $col) . $delim;
      }
      $text .= "\n";
      return $text;
    }

    if ((@rowHeight > 0) && (@colWidth > 0)) {
      $text .= drawSeparator("top", \@colWidth);
      for my $j (0 .. $#rowHeight) {
        for my $k (0 .. $rowHeight[$j]-1) {
          $text .= "|";
          for my $i (0 .. $#colWidth) {
            my $line = $cellText[$j][$i][$k];
            if (defined($line)) {
              $text .= $line . (" " x ($colWidth[$i] - length($line)));
            }
            else {
              $text .= " " x ($colWidth[$i]);
            }
            $text .= "|";
          }
          $text .= "\n";
        }
        $text .= drawSeparator("mid", \@colWidth) if $j != $#rowHeight;
      }
      $text .= drawSeparator("bottom", \@colWidth);
    }

  }
    
  return $text;
}

sub getCellsAsText {
  my ($self, $args) = @_;

  my @cells;
  if ($self->{children}) {
    foreach my $child (@{$self->{children}}) {
      my $type = lc($child->{type});
      if ($type eq "td" || $type eq "th") {
        my $text = $child->serializeAsText();
        $text =~ s/^[\s\n]+//;
        push(@cells, $text);
      }
    }
  }
  return \@cells;
}


# getHead
#
# return the head object
sub getHead {
  my $self = shift;
  croak("getHead() can only be called on 'page' nodes") if $self->{type} ne "page";
  return $self->{head};
}

# getBody
#
# return the body object
sub getBody {
  my $self = shift;
  croak("getBody() can only be called on 'page' nodes") if $self->{type} ne "page";
  return $self->{body};
}


# parent
#
# return the parent of the object
sub parent {
  my $self = shift;
  return $self->{parent};
}


# Catch all for new elements - note that we allow anything here and
# don't error check to make sure it is a valid HTML element
# - If the element name ends in an underscore, we return the parent
#   otherwise we will return the parent.
sub AUTOLOAD {
  my ($self, $content, $attrs) = @_;
  our $AUTOLOAD;

  if (ref($content) eq "HASH") {
    $attrs   = $content;
    $content = undef;
  }

  my ($element, $returnParent) = ($AUTOLOAD =~ /::([A-Za-z0-9]+)(_)?$/);

  if (!defined($element)) {
    croak("Unexpected HTML element name: $AUTOLOAD");
  }

  my $child = HTML::Simple2->new({type    => $element,
                                  content => $content,
                                  attrs   => $attrs,
                                  parent  => $self
                                 });
  push(@{$self->{children}}, $child);
  if ($returnParent) {
    return $self;
  }

  return $child;

}

sub DESTROY {
}

1;
