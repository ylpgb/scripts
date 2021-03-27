package Solace::Sm::Cmd::Admin::Clean;

use warnings;
use base Solace::Sm::Cmd::Base;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  my $dir = $rtr->getDir();
  my $pid = $rtr->getPid();

  $self->info("Cleaning router " . $rtr->getName());
  if ($pid) {
    system("/bin/kill $pid");
    waitpid($pid, 0);
  }
  system("rm -fr $dir");
  my $lnname = "$ENV{HOME}" . "/.sm/solacedaemon.pid." . $rtr->getNum();
  system("rm -f $lnname");
}


1;


