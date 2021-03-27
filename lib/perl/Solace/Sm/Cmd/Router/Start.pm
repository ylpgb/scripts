package Solace::Sm::Cmd::Router::Start;

use warnings;
use base Solace::Sm::Cmd::Router;

use Solace::Sm::Env;
use Solace::Sm::Cmd::Router::Init;

use File::Copy;
use File::Temp qw/ tempfile /;

sub doRun() {
  my $self = shift();
  my @rtrs = $self->SUPER::doRun();

  ## Initialize any routers started if needed.
  if ($self->{args}{init}) {
    foreach my $rtr (@rtrs) {
      my $cmd = Solace::Sm::Cmd::Router::Init->new($self->{args});
      $cmd->doRunSingle($rtr);
    }
  }
  elsif ($self->{args}{wait}) {
    foreach my $rtr (@rtrs) {
      ## Wait longer for production routers -- they take longer to start
      ## up.
      my $retryCount = $rtr->isDev() ? 10 : 30;
      $self->poll($rtr, $retryCount);
    }
  }
}

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  my $pid = $rtr->getPid();
  if ($pid) {
    $self->fatal("Router " . $rtr->getName() . " appears to be started already");
  }
  else {
    $self->setupScriptsDir($rtr);

    $self->rmDbIfNeeded($rtr);

    $self->info("Starting router " . $rtr->getName() . "...");
    my $pid = fork();
    if (!$pid) {
      if ($rtr->isDev()) {
        $self->startDevRouter($rtr);
      }
      else {
        $self->startProdRouter($rtr);
      }
      ## Not expecting these to return.
      $self->fatal("Start should exec");
    }
  }
}

sub startDevRouter($) {
  my $self = shift();
  my $rtr = shift();

  my $dir    = $rtr->getDir();
  my $hport  = $rtr->getPort("http");
  my $hsport = $rtr->getPort("https");
  my $tport  = $rtr->getPort("tcp");
  my $uport  = $rtr->getPort("udp");
  my $name   = $rtr->getName();

  ## In case we are not asking to init, don't override the hostname in
  ## case it has been changed.
  if (!$self->{args}{init}) {
      $name = "";
  }

  my $soldm = $Solace::Sm::Env::soldm;
  my $cvswd = $Solace::Sm::Env::cvswd;
  my $ldpath = $Solace::Sm::Env::ldpath;
  my $env = "CVSWD=$cvswd LD_LIBRARY_PATH=$ldpath";
  my $logfile = "$dir/log.txt";
  my $ss = $rtr->getSolaceStartup($rtr);

  ## To detect collisions regardless of where the home dir of the
  ## simulator is, put a link to this instance's solacedaemon.pid file
  ## in $HOME/.sm
  my $lnname = "$ENV{HOME}" . "/.sm/solacedaemon.pid." . $rtr->getNum();
  $rtr->lnDirFile("solacedaemon.pid", $lnname);

  ## Source setup script and invoke solacedaemon with the proper
  ## environment.
  my $cmd = "$env HSPORT=$hsport HPORT=$hport TPORT=$tport UPORT=$uport DIR=$dir NAME=$name $soldm -d $dir -o -l WARN -f $ss > $logfile &";
  $rtr->execOnHost($cmd);
}

sub startProdRouter($) {
  my $self = shift();
  my $rtr = shift();
  $rtr->execOnHost("service solace start >& /dev/null &");
}

sub setupScriptsDir($)
{
  my $self = shift();
  my $rtr = shift();

  ## Create a soldebuginitrc file on the host that chooses our correct
  ## operating mode.  Use the scripts/soldebuginitrc file as a base if
  ## it exists, or scripts/_soldebuginitrc file if it does not.  This
  ## allows designer-specific changes to be maintained.

  my $mode = $rtr->getMode();
  my $dir = $Solace::Sm::Env::cvswd . "/solcbr/scripts";
  my $file = $dir . "/soldebuginitrc";
  if (! -r $file) {
    $file = $dir . "/_soldebuginitrc";
  }

  my ($tmpFh, $tmpFile) = tempfile(UNLINK => 1);
  if (-r $file) {
    copy($file, $tmpFile);
  }

  ## Get the JNDI schema file name (mode specific)
  my $jndiRcFile = "";

  print `echo "" >> $tmpFile`;
  print `echo "# ADDED BY SOLSM" >> $tmpFile`;

  if ($mode eq "tma") {
    print `echo '## Set TMA Mode' >> $tmpFile`;
    print `echo 'persistObjSysParmSet "operatingMode", "1"' >> $tmpFile`;
  }
  if ($mode eq "solos") {
    print `echo '## Set SolOS Mode' >> $tmpFile`;
    print `echo 'persistObjSysParmSet "operatingMode", "2"' >> $tmpFile`;
    $jndiRcFile = $dir . "/soldebugjndicrrc";
  }
  if ($mode eq "soltr") {
    print `echo '## Set SolTR Mode' >> $tmpFile`;
    print `echo 'persistObjSysParmSet "operatingMode", "3"' >> $tmpFile`;
    $jndiRcFile = $dir . "/soldebugjnditrrc";
  }

  my $relativePathScriptsDir = "loads/currentload/scripts";
  my $fullPathScriptsDir = $rtr->getDir() . "/$relativePathScriptsDir";
  $rtr->runOnHost("mkdir -p $fullPathScriptsDir");

  $rtr->copyFileToDir($tmpFile, "$relativePathScriptsDir/soldebuginitrc");

  ## Copy current soldebugjndirc file to host.
  if ($jndiRcFile ne "") {
    $rtr->copyFileToDir($jndiRcFile, "$relativePathScriptsDir/soldebugjndirc");
  }

  $rtr->copyFileToDir("$dir/solDbQuery", "$relativePathScriptsDir");

  my $rcdir = $dir;
  if (!-r "$dir/commonReturnCodes.pm") {
      $rcdir = "$Solace::Sm::Env::objdir/etc";
  }
  $rtr->copyFileToDir("$rcdir/commonReturnCodes.pm", "$relativePathScriptsDir");

  $rtr->copyFileToDir("$dir/commonLogging.pm", "$relativePathScriptsDir");
  $rtr->copyFileToDir("$dir/commonVariables.pm", "$relativePathScriptsDir");
  $rtr->copyFileToDir("$dir/solseed.pm", "$relativePathScriptsDir");
}

sub rmDbIfNeeded($) {
  my $self = shift();
  my $rtr = shift();

  my @dbFiles = ("loads/currentload/db/persistObj*",
                 "loads/currentload/db/dbBaseline*",
                 "loads/currentload/db/dbJournal*");

  ## If not already removing the db, check if the existing db has the
  ## same operating mode as requested for the command.
  ##
  ## TODO: We only check for mode mixup for dev router.
  if ($self->{args}{db} && $rtr->getMode() && $rtr->isDev()) {
      my $dbMode = $rtr->getDbMode();
      if ($dbMode ne $rtr->getMode()) {
          ## Mismatch between requested mode and the mode of the
          ## existing db.
          my $name = $rtr->getName();
          $self->warn("Existing db for router $name has opMode '$dbMode'.");
          $self->warn("Requesting opMode '" . $rtr->getMode() . "' will fail.");
          $self->warn("Force empty db (y/n)?");
          my $key = getc(STDIN);
          if ($key ne "y") {
              $self->fatal("Operating mode mismatch");
          }
          $self->{args}{db} = 0;
      }
  }

  if (!$self->{args}{db}) {
      $self->info("Removing db for router " . $rtr->getName());
      foreach $dbFile (@dbFiles) {
          $rtr->rmDirFile($dbFile);
      }
  }
}

1;


