package Solace::Sm::Cmd::Show::Cspf;

use warnings;
use base Solace::Sm::Cmd::Show;
use Solace::Sm::Cspf::Link;

use XML::XPath;

## Provided a rtr and list of all rtrs, return for the given rtr its
## list of Cspf::Links to the given list of all rtrs.
##
sub getLinks($$) {
  my $self = shift();
  my ($rtr, $allRtrsRef) = @_;
  my @allRtrs = @$allRtrsRef;

  ## Build a hash which can be used to map a name for a neighbor into
  ## the rtr object from the list of all rtrs.
  my %nameToRtr;
  for my $r (@allRtrs) {
    my $name;
    if ($rtr->getMode() eq "solos") {
      $name = $r->getMsgBbIp() . ":" . $r->getPort("tcp");
    }
    else {
      $name = $r->getNbrName();
    }
    $nameToRtr{$name} = $r;
  }

  $self->debug("Getting neighbors of router " . $rtr->getName());

  my $show_cspf_neighbor = "<show><cspf><neighbor><physical-router-name>*</physical-router-name></neighbor></cspf></show>";
  if ($rtr->getMode() eq "solos") {
      $show_cspf_neighbor = "<show><cspf><neighbor/></cspf></show>";
  }

  my ($status, $xml) = $self->sempRpcReply($rtr, $show_cspf_neighbor);

  my @ret = ();
  if ($status !~/^200/) {
    $self->error("$status");
    return @ret;
  }

  my $xp = XML::XPath->new(xml => $xml);
  my @nbrContexts = $xp->findnodes("//neighbors/neighbor");

  $self->debug("Router " . $rtr->getName() . " has neighbors:");
  foreach my $context (@nbrContexts) {
    my $name;
    if ($rtr->getMode() eq "solos") {
      my $ip = $xp->findnodes("./address/text()", $context);
      my $port = $xp->findnodes("./port/text()", $context);
      $name = $ip  . ":" . $port;
    }
    else {
      $name = $xp->findnodes("./name/text()", $context);
    }
    my $state = $xp->findnodes("./state/text()", $context);

    ## Should the lookup into the hash fail, an undef will be returned
    ## as one of the routers.  The caller should handle this.
    push(@ret, Solace::Sm::Cspf::Link->new($nameToRtr{$name}, $state));
  }

  return @ret;
}

1;


