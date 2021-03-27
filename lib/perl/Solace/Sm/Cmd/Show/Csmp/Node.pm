package Solace::Sm::Cmd::Show::Csmp::Node;

use warnings;
use base Solace::Sm::Cmd::Show::Csmp;

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
    my @nodes = $self->getNodes($rtr, \@rtrs);

    my $num = $rtr->getNum();
    my @row = @emptyRow;
    $row[0] = $num;

    for my $node (@nodes) {
      $row[$num+1] = "x";  ## No link to ourselves.
      if ($node->getRtr()) {
	$row[$node->getRtr()->getNum()+1] = $node->getState();
      }
    }
    $table->load(\@row);
  }

  $self->msg($table);
}

1;


