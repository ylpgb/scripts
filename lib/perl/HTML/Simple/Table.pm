#############################################################################
##
## HTML::Simple::Table
##
## This module will add a table to the simple HTML object
##
#############################################################################

package HTML::Simple::Table;

use strict;
use warnings;
use Data::Dumper;
use Carp;


# new - create a new object to interact with a specific router
#
# Parameters:
#   o caption     - Caption of the table
#   o headings    - Array of headings - can be array of arrays
#   o rows        - Array of arrays of row data
#   o footers     - Array of footers - can be array of arrays
#   o classPrefix - Each element will be given a class name with this prefix
#   o noDefClass  - If true, the default classes will not be added to the elements
#   o tableId     - ID added to the table (if present)
#   o classes     - Hash of additional classes: 
#                       {table => ['x', 'y', ...], 
#                        thead => ['x', 'y', ...], 
#                        tfoot => ['x', 'y', ...],
#                        th    => ['x', 'y', ...],
#                        tr    => ['x', 'y', ...],
#                        td    => ['x', 'y', ...]}
#  
#  Note that for all cell values in the arrays above, the value can either be a
#  scalar that will simply be added to the cell or it can be a hash of pairs that
#  are all the attributes for that cell element plus 'VALUE' => <cellValue> which
#  which will be used for the cell value.
#

sub new {
  my $class = shift;
  my %args  = @_;

  map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{rows};
  
  my %defaults = (caption     => "",
                  headings    => [],
                  rows        => undef,
                  footers     => [],
                  classPrefix => "default",
                  noDefClass  => 0,
                  tableId     => undef,
                  classes     => {});

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

  my %classes;
  foreach my $type (qw{table thead tfoot tbody th tr td}) {
    push(@{$classes{$type}}, @{$self->{classes}{$type}}) if defined $self->{classes}{$type};
    push(@{$classes{$type}}, "$self->{classPrefix}_$type") if !$self->{noDefClass};
  }

  my $html = "";

  $html .= "<table";
  $html .= " id='$self->{tableId}'" if defined($self->{tableId});
  $html .= " class='@{$classes{table}}'" if @{$classes{table}};
  $html .= ">\n";

  if (@{$self->{headings}}) {
    $html .= $self->serializeRows($self->{headings}, 
                                  "th", "thead", \%classes);
  }

  if (@{$self->{rows}}) {
    $html .= $self->serializeRows($self->{rows}, 
                                  "td", "tbody", \%classes);
  }

  if (@{$self->{footers}}) {
    $html .= $self->serializeRows($self->{footers}, 
                                  "td", "tfoot", \%classes);
  }

  $html .= "</table>\n";

  return $html;

}


# serializeRows - generate HTML for table rows

sub serializeRows {
  my ($self, $rows, $cellType, $blockType, $classes) = @_;

  my $html;

  $html .= "<$blockType";
  $html .= " class='@{$classes->{$blockType}}'" if @{$classes->{$blockType}};
  $html .= ">\n";
  
  if (ref($rows->[0]) eq "ARRAY") {
    # Array of Arrays
    foreach my $row (@{$rows}) {
      $html .= "<tr";
      $html .= " class='@{$classes->{tr}}'" if @{$classes->{tr}};
      $html .= ">\n";
      foreach my $cell (@{$row}) {
        $html .= $self->serializeCell($cell, $cellType, $classes);
      }
      $html .= "</tr>\n";
    }
  }
  else {

    $html .= "<tr";
    $html .= " class='@{$classes->{tr}}'" if @{$classes->{tr}};
    $html .= ">\n";
    foreach my $cell (@{$rows}) {
      $html .= $self->serializeCell($cell, $cellType, $classes);
    }
    $html .= "</tr>\n";
    
  }

  $html .= "</$blockType>\n";

  return $html;

}


# serializeCell - generate HTML for a single cell

sub serializeCell {
  my ($self, $cell, $cellType, $classes) = @_;

  my $value;
  my @attrs;
  my @classes = @{$classes->{$cellType}};
  if (ref($cell) eq "HASH") {
    $value = defined($cell->{VALUE}) ? $cell->{VALUE} : "";
    foreach my $attr (keys(%{$cell})) {
      next if $attr eq "VALUE";
      if ($attr =~ /^class$/i) {
        push(@classes, $cell->{$attr});
        next;
      }
      push(@attrs, "$attr = '$cell->{$attr}'");
    }
  }
  elsif (ref($cell) eq "HTML::Simple::Container") {
    $value = $cell->serialize();
  }
  else {
    $value = $cell;
  }

  my $html;

  $html .= "<$cellType";
  $html .= " class='@classes'" if @classes;
  $html .= " @attrs" if @attrs;
  $html .= ">\n";

  $html .= "$value\n";
  $html .= "</$cellType>\n";

  return $html;

}


# getDefaultCss - return some default CSS for a table
#
sub getDefaultCss {
  my ($self, %args) = @_;

  my $css;

  my $prefix = $args{classPrefix} || $self->{classPrefix} || "default";

  if (!$args{skipFont}) {

    $css .= "
table.${prefix}_table {
    font-family: helvetica, verdana, arial, sans-serif;
    color:       #000080;
}
";
  }

  $css .= "
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

";

}


1;
