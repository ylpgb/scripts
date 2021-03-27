package Solace::Sm::Cmd::Show::Cspf::Nbr;

use warnings;
use base Solace::Sm::Cmd::Show::Cspf;

sub doRun() {
  my $self = shift();
  my @rtrs = $self->getRouters();

  my @rtrNums;
  foreach $rtr (@rtrs) {
    push(@rtrNums, $rtr->getNum());
  }

  my $table = $self->getRouterNumTable(\@rtrNums);

  my @emptyRow;
  for (1..$table->n_cols()) {
    push(@emptyRow, "-");
  }

  foreach my $rtr (@rtrs) {
    my @links = $self->getLinks($rtr, \@rtrs);

    my $num = $rtr->getNum();
    my @row = @emptyRow;
    $row[0] = $num;

    for my $link (@links) {
      $row[$num+1] = "x";  ## No link to ourselves.
      if ($link->getRtr()) {
	$row[$link->getRtr()->getNum()+1] = $link->getState();
      }
    }
    $table->load(\@row);
  }

  $self->msg($table);
}

1;


