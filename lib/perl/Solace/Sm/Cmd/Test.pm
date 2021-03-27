package Solace::Sm::Cmd::Test;

use warnings;
use base Solace::Sm::Cmd::Base;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();
  my $name = $rtr->getName();
  my $dir = $rtr->getDir();
  ##$self->msg("msg: Testing router number $name in $dir");
  ##$self->debug("debug: Testing router number $name in $dir");
  ##$self->info("info: Testing router number $name in $dir");
  ##$self->warn("warn: Testing router number $name in $dir");
  ##$self->error("error: Testing router number $name in $dir");
  ##$self->fatal("fatal: Testing router number $name in $dir");
  $self->msg("LD_LIBRARY_PATH=" . "$Solace::Sm::Env::ldpath");
}

1;


