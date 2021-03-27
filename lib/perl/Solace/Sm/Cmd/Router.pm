package Solace::Sm::Cmd::Router;

use warnings;
use base Solace::Sm::Cmd::Base;

## Poll the given router until it seems responsive.  Will die if not
## reached within the given retry count.
##
sub poll($$) {
  my $self = shift();
  my ($rtr, $retry) = @_;

  ## Send a SEMP "show version" until we get a 200 response, or our
  ## retry count is reached.
  while ($retry > 0) {
    $self->debug("Polling router " . $rtr->getName() . ", $retry attempts remaining");
    my $status = $self->sempRpc($rtr, "<show><version/></show>");
    $self->debug("Status: $status");
    if ($status =~/^200/) {
      return;
    }
    $retry--;
    sleep(5);
  }
  $self->fatal("Polling router " . $rtr->getName() . " failed");
}

1;


