#############################################################################
##
## HTML::Simple::Skins
##
## This module will add a skins to the simple HTML object
##
#############################################################################

package HTML::Simple::Skins;

use strict;
use warnings;
use Data::Dumper;
use Carp;


my %skins = (
  default => {
    body => '
    ',
    bodyFont => '
body {
    font-family: helvetica, verdana, arial, sans-serif;
    color:       #000080;
}
    ',
    table =>  '
table.${prefix}_table {
   text-align: left;
}

td.${prefix}_td {
    vertical-align: top;
    text-align:       right;
    background-color: #ccccff;
    padding:          0.2em;
}

th.${prefix}_th {
    background-color: #aaaaff;
    padding:          0.2em;
}
    ',
    tableFont => '
table.${prefix}_table {
    font-family: helvetica, verdana, arial, sans-serif;
    color:       #000080;
}
    ',
  },
);



# new - create a new object to interact with a specific router
#

sub new {
  my $class = shift;
  my %args  = @_;

  # map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{rows};
  
  my %defaults = (skin => "default");

  my %self = %args;

  foreach my $key (keys(%defaults)) {
    if (!defined($self{$key})) {
      $self{$key} = $defaults{$key};
    }
  }

  bless(\%self, $class);

  return \%self;

}




# getCss - return CSS for the specified skin
#
sub getCss {
  my ($self, $skinName, %args) = @_;

  my $css;

  $skinName = "default" if !defined($skinName) && (!defined($self) || !defined($self->{skin}));
  $skinName = $self->{skin} if !defined($skinName);

  my $prefix = $args{prefix} || $self->{prefix} || "default";

  if (!defined($skins{$skinName})) {
    carp("Skin $skinName does not exist");
    return "";
  }

  my @blocks;
  foreach my $block (keys(%{$skins{$skinName}})) {
    next if defined($args{exceptions}) && grep(/^$block$/, @{$args{exceptions}});
    next if $args{skipFont} && $block =~ /font/i;
    next if defined($args{blocks}) && !grep(/^$block$/, @{$args{blocks}});
    push(@blocks, $block);
  }

  foreach my $block (@blocks) {
    $css .= $skins{$skinName}{$block};
  }

  eval("\$css = \"$css\";");

  return $css;

}


1;
