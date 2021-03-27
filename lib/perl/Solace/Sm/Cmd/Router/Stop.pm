package Solace::Sm::Cmd::Router::Stop;

use warnings;
use base Solace::Sm::Cmd::Router;

sub doRun() {
  my $self = shift();
  my @rtrs = $self->SUPER::doRun();

  if ($self->{args}{wait}) {
    ## Wait for all routers to stop.
    foreach my $rtr (@rtrs) {
      $self->info("Waiting for router " . $rtr->getName() . " to stop...");
      while ($rtr->getPid()) {
	sleep(1);
      }
    }
  }
}

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  my $pid = $rtr->getPid();
  if ($pid) {
    $self->info("Stopping router " . $rtr->getName() . "...");
    if ($rtr->isDev()) {
      $self->stopDevRouter($rtr);
    }
    else {
      $self->stopProdRouter($rtr);
    }
  }
  else {
    $self->warn("Router " . $rtr->getName() . " appears to be stopped already");
  }
}

sub stopDevRouter($) {
  my $self = shift();
  my $rtr = shift();
  my $pid = $rtr->getPid();
  if ($pid) {
    system("/bin/kill $pid");
  }
}

sub stopProdRouter($) {
  my $self = shift();
  my $rtr = shift();
  $rtr->runOnHost("service solace stop >& /dev/null &");
}

1;


