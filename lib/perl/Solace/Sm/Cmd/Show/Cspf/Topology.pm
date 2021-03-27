package Solace::Sm::Cmd::Show::Cspf::Topology;

use warnings;
use base Solace::Sm::Cmd::Show::Cspf;

use Data::Dumper;
use Graph::Easy;

sub doRun() {
  my $self = shift();
  my @rtrs = $self->getRouters();

  my $graph = Graph::Easy->new(timeout => "60");

  foreach my $rtr (@rtrs) {
    my @links = $self->getLinks($rtr, \@rtrs);
    my $num = $rtr->getNum();

    $graph->add_node($num);
    for my $link (@links) {
      ## $link may be undefined, meaning it is unknown.  For such
      ## routers, display a '?' as their number.
      my $nbrNum = "?";
      if ($link->getRtr()) {
	$nbrNum = $link->getRtr()->getNum();
      }

      $graph->add_node($nbrNum);
      ## If an edge to this neighbor already exists, make it
      ## bidirectional, otherwise just add one in the other direction.
      my $edge = $graph->edge($nbrNum, $num);
      if ($edge) {
        $edge->bidirectional(1);
      } else {
        $graph->add_edge_once($num, $nbrNum);
      }
    }
  }
  $self->msg($graph->as_ascii());
}

1;


