#
# UI.pm - this is a set of library functions that provide a 
#         simple user interface for a perl script
#

package UI;

use Term::ReadKey;

use constant BOLD    => "\e[1m";
use constant NORMAL  => "\e[0m";

my $BOLD   = BOLD;
my $NORMAL = NORMAL;
my $BOLDr  = "[31m[1m";  # Red
my $BOLDg  = "[32m[1m";  # Green



##############################################################################
# new - Construct the UI object
#
##############################################################################
sub new {
  my ($class, $options) = @_;

  my $self = {};

  foreach my $key (keys(%{$options})) {
    $self->{$key} = $options->{$key};
  }

  if ($self->{no_color}) {
    $BOLD   = "";
    $NORMAL = "";
  }

  bless($self, $class);
  return $self;

}


##############################################################################
# menu - Create a menu with a prompt
#
#  $obj->menu({title => "Here are your options:",
#              prompt => "Select type",
#              default => "<default value>",
#              items => [{name => "Name for option1", value => 'optVal1'},
#                        {name => "Name for option2", menu => 
#                          {title => 'Sub-menu',
#                           prompt => 'Select type',
#                           items  => ...
#                        },
#                        {name => "Name for option3", func => sub { <code> }}
#                       ]
#            });
#  
#  For option1, 'optVal1' will be returned. For option2, a sub-menu will be
#  launched and its returning value will be returned. For option3, the
#  code will be run. 
#
##############################################################################
sub menu {
  my ($self, $options) = @_;

  my $val;
  while (1) {
    print "\n";
    print "${BOLD}$options->{title}${NORMAL}\n" if $options->{title};
    my $idx = 1;
    my $defaultIdx;
    foreach my $item (@{$options->{items}}) {
      if (ref($item) eq "HASH") {
        printf("  %2d: %s\n", $idx, $item->{name});
        if ($options->{default} && 
            $options->{default} eq $item->{name} ||
            ($item->{value} && $options->{default} eq $item->{value})) {
          $defaultIdx = $idx;
        }
      }
      else {
        printf("  %2d: %s\n", $idx, $item);
        if ($options->{default} && 
            $options->{default} eq $item) {
          $defaultIdx = $idx;
        }
      }
      $idx++;
    }
    my $default = "";
    if ($defaultIdx) {
      $default = " [$defaultIdx]";
    }
    if ($options->{prompt}) {
      print "${BOLD}$options->{prompt}$default$:{NORMAL} ";
    }
    else {
      print "${BOLD}Select item$default:${NORMAL} ";
    }

    $val = <STDIN>;
    if ($val > 0 &&
        $val <= @{$options->{items}}) {
      last;
    }
    elsif ($defaultIdx && $val eq "\n") {
      $val = $defaultIdx;
      last;
    }
    print "${BOLD}Invalid value${NORMAL}\n";
  }
  
  $val--;
  my $selected;
  if (ref($options->{items}[$val]) eq "HASH") {
    if (defined($options->{items}[$val]{menu})) {
      return $self->menu($options->{items}[$val]{menu});
    }
    elsif (defined($options->{items}[$val]{func})) {
      return &{$options->{items}[$val]{func}}();
    }
    $selected = defined($options->{items}[$val]{value}) ?
        $options->{items}[$val]{value} : $options->{items}[$val]{name};
  }
  else {
    $selected = $options->{items}[$val];
  }

  return ($selected, $val) if wantarray;
  return $selected;

} # menu #


##############################################################################
## yOrN - Ask a Y/N question 
##
##############################################################################
sub yOrN {
  my ($self, $prompt) = @_;

  print "${BOLD}$prompt (Y/N): $NORMAL";
  my $ans = <STDIN>;
  return 1 if $ans =~ /^\s*y/i;
  return 0;

} # yOrN #


##############################################################################
## prompt - Prompt the user for input 
##
##############################################################################
sub prompt {
  my ($self, $promptText, $options) = @_;

  $options ||= {};

  my $default = "";
  if (exists($options->{default})) {
    $default = " [$options->{default}]";
  }
  my $colon = ":";
  $colon = "" if $options->{noColon};
  if ($options->{stderr}) {
    print STDERR "${BOLD}$promptText$default$colon ${NORMAL}";
  }
  else {
    print "${BOLD}$promptText$default$colon ${NORMAL}";
  }
  
  if ($options->{noecho}) {
    ReadMode('noecho'); # don't echo
  }

  chomp(my $resp = <STDIN>);

  if ($options->{noecho}) {
    ReadMode(0);        # back to normal
    if ($options->{stderr}) {
      print STDERR "\n";
    }
    else {
      print "\n";
    }
  }  

  if (exists($options->{default})) {
    if ($resp eq "") {
      $resp = $options->{default};
    }
  }
    
  return $resp;

} # prompt #


##############################################################################
## info - Output an informational statement 
##
##############################################################################
sub info {
  my ($self, $statement, $options) = @_;

  $options ||= {};

  if (!$options->{nowrap}) {
    $statement = $self->wordWrap($statement);
  }

  print "$statement\n";

} # info #


##############################################################################
## error - Output an error statement 
##
##############################################################################
sub error {
  my ($self, $statement, $options) = @_;

  $options ||= {};

  if (!$options->{nowrap}) {
    $statement = $self->wordWrap($statement);
  }

  print "Error: $statement\n";

} # error #


##############################################################################
## separator - 
##
## Simple separator between blocks - defaults to a single blank line 
##
##############################################################################
sub separator {
  my ($self, $options) = @_;

  $options ||= {};

  print "\n";

} # separator #


##############################################################################
## wordWrap - Word wrap the specified text 
##
##############################################################################
sub wordWrap {
  my ($self, $text) = @_;

  $text =~ s/(.{1,79})(\s+|$)/$1\n/g;
  chomp($text);

  return $text;

} # wordWrap #


##############################################################################
## table - insert a table with nicely spaced columns 
##
##############################################################################
sub table {
  my ($self, $cfg) = @_;

  my @widths;
  my $padding = " ";
  $padding = " " x $cfg->{padding} if $cfg->{padding};
  
  my $colIdx = 0;
  if ($cfg->{headings}) {
    foreach my $header (@{$cfg->{headings}}) {
      $widths[$colIdx] = length($header);
      $colIdx++;
    }
  }

  foreach my $row (@{$cfg->{rows}}) {
    $colIdx = 0;
    foreach my $item (@{$row}) {
      if (length($item) > $widths[$colIdx]) {
        $widths[$colIdx] = length($item);
      }
      $colIdx++;
    }
  }
  
  my $text = "";
  if ($cfg->{headings}) {
    $colIdx = 0;
    foreach my $header (@{$cfg->{headings}}) {      
      $text .= sprintf("${BOLD}%-$widths[$colIdx]s${NORMAL}$padding", "$header");
      $colIdx++;
    }
    $text .= "\n";
    $colIdx = 0;
    foreach my $header (@{$cfg->{headings}}) {      
      $text .= "${BOLD}" . ("=" x $widths[$colIdx]) . "${NORMAL}$padding";
      $colIdx++;
    }
    $text .= "\n";
  }

  foreach my $row (@{$cfg->{rows}}) {      
    $colIdx = 0;
    foreach my $item (@{$row}) {      
      $text .= sprintf("%-$widths[$colIdx]s$padding", $item);
      $colIdx++;
    }
    $text .= "\n";
  }

  print $text;

} # table #


##############################################################################
## heading - insert a heading with optional underlining 
##
##############################################################################
sub heading {
  my ($self, $text, $options) = @_;

  $options ||= {};

  my $len = length($text);

  my $out = "${BOLD}$text${NORMAL}\n";

  if (!$options->{noUnderline}) {
    $out .= "${BOLD}" . ($options->{underlineChar} || "=") x $len;
    $out .= "${NORMAL}\n\n";
  }
  else {
    $out .= "\n";
  }
  
  print $out;

} # heading #


##############################################################################
## statusBar - 
##
## Insert a status bar and a following message into the terminal. Optionally
## clear the line first 
##
##############################################################################
sub statusBar {
  my ($self, $args) = @_;

  $| = 1;
  if ($args->{clearLine}) {
#    print "\e[80D";
    print "\e[2K\e[0E";
  }

  my $width   = $args->{width};
  my $percent = $args->{percent} > 1 ? $args->{percent}/100 : $args->{percent};

  my $filled  = $width * $percent;
  my $rest    = $width - $filled;

#  print "$width, $filled, $rest\n";
  print "[" . ('=' x $filled) . (" " x $rest) . "] $args->{status}";

} # statusBar #



1;
