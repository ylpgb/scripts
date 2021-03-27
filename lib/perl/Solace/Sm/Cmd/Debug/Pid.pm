package Solace::Sm::Cmd::Debug::Pid;

use warnings;
use base Solace::Sm::Cmd::Base;

use Solace::Sm::Env;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();
  my $child = $self->{args}{child};
  if (defined($Solace::Sm::Env::exeAlias{$child})) {
    $child = $Solace::Sm::Env::exeAlias{$child};
  }
  my $pid = $rtr->getPid($child);
  if ($pid) {
    $self->msg("$pid");
  }
}

1;


