package Solace::Sm::Cmd::Debug::Gdb;

use warnings;
use base Solace::Sm::Cmd::Base;

use Solace::Sm::Env;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();
  my $exe = $self->{args}{executable};

  if (defined($Solace::Sm::Env::exeAlias{$exe})) {
    $exe = $Solace::Sm::Env::exeAlias{$exe};
  }

  my $bin = "$Solace::Sm::Env::bindir/$exe";
  if ($exe eq "cli") {
      my $ldpath = $Solace::Sm::Env::ldpath;
      my $env = "CVSWD=$cvswd LD_LIBRARY_PATH=$ldpath";
      my $cliArgs = "-A -d " . $rtr->getDir();
      exec("$env gdb --eval-command=run --args $bin $cliArgs");
  }

  my $pid = $rtr->getPid($exe);
  exec("gdb $bin $pid");
}

1;


