package Solace::Sm::Cmd::Debug::Semp;

use warnings;
use base Solace::Sm::Cmd::Base;

use XML::XPath;
use XML::XPath::XMLParser;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  if ($self->{args}{string} && $self->{args}{file}) {
    $self->error("Provide only one of --string or --file");
  }
  else {
    if ($self->{args}{xml}) {
      my $xmlIn = $self->{args}{xml};
      my ($status, $xmlOut) = $self->sempRpcReply($rtr, $xmlIn);
      $self->msg($xmlOut);
    }
    else {
      if (! -r $self->{args}{file}) {
	$self->error("File " . $self->{args}{file} . " not found");
      }
      else {
	my $xp = XML::XPath->new(filename => $self->{args}{file});
	my $nodes = $xp->find("/rpc/*");
	foreach my $node ($nodes->get_nodelist()) {
	  my $xmlIn = XML::XPath::XMLParser::as_string($node);
	  my ($status, $xmlOut) = $self->sempRpcReply($rtr, $xmlIn);
	  $self->msg($xmlOut);
	}
      }
    }
  }
}

1;


