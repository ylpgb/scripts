package Solace::Sm::Cmd::Show;

use warnings;
use base Solace::Sm::Cmd::Base;

use Text::Table;

## Return a table with row and columns representing the given routers
## by their number.
sub getRouterNumTable($) {
  my $self = shift();
  my ($numsRef) = @_;

  my @heading = "Router";
  foreach my $num (@$numsRef) {
    push(@heading, $num);
  }
  my $table = Text::Table->new(@heading);

  return $table;
}

1;


