package Solace::Sm::Cmd::Show::Csmp;

use warnings;
use base Solace::Sm::Cmd::Show;
use Solace::Sm::Csmp::Node;

use XML::XPath;

## Provided a rtr and list of all rtrs, return for the given rtr its
## list of Csmp::Node to the given list of all rtrs.
##
sub getNodes($$) {
  my $self = shift();
  my ($rtr, $allRtrsRef) = @_;
  my @allRtrs = @$allRtrsRef;

  ## Build a hash which can be used to map an ip/port for a node into
  ## the rtr object from the list of all rtrs.
  my %ipPortToRtr;
  for my $r (@allRtrs) {
    my $ipPort = $r->getMsgBbIp() . ":" . $r->getPort("http");
    $ipPortToRtr{$ipPort} = $r;
  }

  my $num = $rtr->getNum();

  $self->debug("Getting csmp nodes of router $num");

  my $show_csmp_node = "<show><csmp><node/></csmp></show>";
  my ($status, $xml) = $self->sempRpcReply($rtr, $show_csmp_node);

  my @ret = ();
  if ($status !~/^200/) {
    $self->error("$status");
    return @ret;
  }

  my $xp = XML::XPath->new(xml => $xml);
  my @nodeContexts = $xp->findnodes("//csmp/node/nodes/node");

  $self->debug("Router $num has csmp nodes:");
  foreach my $context (@nodeContexts) {
    my $ip = $xp->findnodes("./ip-address/text()", $context);
    my $port = $xp->findnodes("./port/text()", $context);
    my $state = $xp->findnodes("./status/text()", $context);
    my $ipPort = $ip  . ":" . $port;

    ## Should the lookup into the hash fail, an undef will be returned
    ## as one of the routers.  The caller should handle this.
    push(@ret, Solace::Sm::Csmp::Node->new($ipPortToRtr{$ipPort}, $state));
  }

  return @ret;
}


1;


