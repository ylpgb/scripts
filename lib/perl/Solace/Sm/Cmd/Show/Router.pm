package Solace::Sm::Cmd::Show::Router;

use warnings;
use base Solace::Sm::Cmd::Show;

use Text::Table;
use XML::XPath;

sub doRun() {
  my $self = shift();
  my @rtrs = $self->getRouters();
  my $tb = Text::Table->new("Name", "Run?", "MgmtIp", "MsgBbIp", "TCP Port", "Version");
  foreach my $rtr (@rtrs) {
    my $run = $rtr->getPid() ? "yes" : "no";
    my $ver = $self->getVersion($rtr);
    $tb->load([$rtr->getName, $run, 
	       $rtr->getMgmtIp(), $rtr->getMsgBbIp(), 
	       $rtr->getPort("tcp"), $ver]);
  }
  $self->msg($tb);
}

sub getVersion($) {
  my $self = shift();
  my $rtr = shift();

  my $ver = "unknown";
  my ($status, $xml) = $self->sempRpcReply($rtr, "<show><version/></show>");
  if ($status =~ m/^200/) {
    my $xp = XML::XPath->new(xml => $xml);
    $ver = $xp->findnodes("//show/version/current-load");
  }
  return $ver;
}

1;


