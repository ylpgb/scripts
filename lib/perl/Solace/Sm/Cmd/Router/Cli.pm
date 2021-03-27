package Solace::Sm::Cmd::Router::Cli;

$| = 1;

use warnings;
use base Solace::Sm::Cmd::Router;
use File::Temp;
use File::Slurp;

use Solace::Sm::Env;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  ## Startup script that will be written into the router's
  ## jail/cliscripts
  my $ssString;
  my $extraCliArgs = "";

  ## Session timeout.
  $ssString .= "session timeout -1\n";

  if ($self->{args}{script}) {
    $ssString = File::Slurp::read_file($self->{args}{script});
    $extraCliArgs .= "-p";
  }
  else {
    $ssString = "enable\nconfigure\nno paging\n";
  }

  ## May be interactive, or given a list of commands to execute.
  ##
  my $exec = $self->{args}{execute};
  if ($exec) {
    ## Continue to build ssString to execute what was given and then
    ## logout.
    $ssString = join("\n", $ssString, split(/\\/, $exec), "logout");
  }
  my $dir = $rtr->getDir();
  my $cmd = "echo \'$ssString\' > $dir/jail/cliscripts/sm_startup";
  $rtr->runOnHost($cmd);

  $self->info("Starting cli for router ". $rtr->getName());

  my $pid = fork();
  if (!$pid) {
    if ($rtr->isDev()) {
      print $self->cliDevRouter($rtr, "sm_startup", $extraCliArgs);
    }
    else {
      print $self->cliProdRouter($rtr, "sm_startup", $extraCliArgs);
    }
  }
  else {
    waitpid($pid, 0);
  }
}

sub cliDevRouter($$) {
  my $self = shift();
  my ($rtr, $script, $extraCliArgs) = @_;

  my $dir = $rtr->getDir();
  my $solcli = $Solace::Sm::Env::solcli;
  my $cvswd = $Solace::Sm::Env::cvswd;
  my $ldpath = $Solace::Sm::Env::ldpath;
  my $env = "CVSWD=$cvswd LD_LIBRARY_PATH=$ldpath";

  my $toArgs = "-u -1";
  my $cmd = "$env $solcli -d $dir -A $toArgs -s $script $extraCliArgs";
  $rtr->execOnHost($cmd);
}

sub cliProdRouter($$) {
  my $self = shift();
  my ($rtr, $script, $extraCliArgs) = @_;

  my $dir = $rtr->getDir();
  my $solcli = "$dir/loads/currentload/bin/cli";

  my $toArgs = "-u -1";
  my $cmd = "$solcli -A $toArgs -s $script $extraCliArgs";
  $rtr->execOnHost($cmd);
}

1;


