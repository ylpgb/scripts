package Solace::Sm::Cmd::Debug::Soldebug;

use warnings;
use base Solace::Sm::Cmd::Base;
use File::Temp;
use File::Slurp;

use Solace::Sm::Env;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  my $dir = $rtr->getDir();
  my $soldbg = $Solace::Sm::Env::soldbg;

  $self->info("Starting soldebug for router " . $rtr->getName());
  my $pid = fork();
  if (!$pid) {
    if ($rtr->isDev()) {
      print $self->soldbgDevRouter($rtr);
    }
    else {
      print $self->soldbgProdRouter($rtr);
    }
  }
  waitpid($pid, 0);
}

sub soldbgDevRouter($) {
  my $self = shift();
  my ($rtr) = @_;

  my $dir = $rtr->getDir();
  my $soldbg = $Solace::Sm::Env::soldbg;
  my $cvswd = $Solace::Sm::Env::cvswd;
  my $ldpath = $Solace::Sm::Env::ldpath;
  my $env = "CVSWD=$cvswd LD_LIBRARY_PATH=$ldpath";
  my $cmd = "$env $soldbg -d $dir";
  $rtr->execOnHost($cmd);
}

sub soldbgProdRouter($) {
  my $self = shift();
  my ($rtr) = @_;

  my $dir = $rtr->getDir();
  my $soldbg = "$dir/loads/currentload/bin/soldebug";

  my $cmd = "$soldbg -d $dir";
  $rtr->execOnHost($cmd);
}

1;


