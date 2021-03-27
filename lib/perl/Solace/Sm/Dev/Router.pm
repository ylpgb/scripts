package Solace::Sm::Dev::Router;

use warnings;
use base Solace::Sm::Router;
use File::Copy;

sub isDev() {
  my $self = shift();
  return 1;
}

sub getDir() {
  my $self = shift();
  return $self->{solsmdir} . "/sm/" . $self->getNum();
}

sub getSolaceStartup() {
  my $self = shift();
  return $self->{solsmdir} . "/sm/SolaceStartup.txt";
}

sub runOnHost($) {
  my $self = shift();
  my $cmd = shift();
  return `ssh $self->{host} "$cmd"`;
}

sub getMsgBbIp() {
  my $self = shift();
  ## Development uses the same address for management as msg-backbone.
  return $self->getMgmtIp();
}

sub execOnHost($) {
  my $self = shift();
  my $cmd = shift();
  exec("ssh $self->{host} -t $cmd");
}

sub lnDirFile($$) {
  my $self = shift();
  my $file = $self->getDir() . "/" . shift();
  my $dest = shift();

  system("ln -sf $file $dest");
}

sub copyFileToDir($$) {
  my $self = shift();
  my $localFile = shift();
  my $remoteFile = $self->getDir() . "/" . shift();
  return `scp $localFile $self->{host}:$remoteFile`;
}

sub doInitDirs($) {
  my $self = shift();
  $self->{solsmdir} = shift();

  setupSolsmDir($self->{solsmdir});

  my $dir = $self->getDir();

  mkdir("$dir");
  mkdir("$dir/loads");
  mkdir("$dir/loads/currentload");
  mkdir("$dir/loads/currentload/schema");
  mkdir("$dir/loads/currentload/system");
  mkdir("$dir/loads/currentload/bin");
  mkdir("$dir/loads/currentload/lib");
}

sub doInit($) {
  my $self = shift();
  my $dir = $self->getDir();

  File::Copy::copy($self->getSempRpcXsd(), "$dir/loads/currentload/schema");

  my $cvswd = $Solace::Sm::Env::cvswd;

  my $stunnelSrc = "$cvswd/solcbr/packaging/bin/stunnel";
  my $stunnelDst = "$dir/loads/currentload/bin/stunnel";
  if (-r $stunnelSrc && ! -r $stunnelDst) {
    # Couldn't get File::Copy to preserve the executable status of the file
    # even with the ::cp and ::syscopy variants - backing off to tried and true
    `cp $stunnelSrc $stunnelDst`;
  }

  my $objdir = $Solace::Sm::Env::objdir;

  my $libpplSrc = "$objdir/lib/libppl.so";
  my $libpplDst = "$dir/loads/currentload/lib/libppl.so";
  if (-r $libpplSrc) {
    `cp $libpplSrc $libpplDst`;
  }

  ## Choose our ports.
  $self->{ports}{http}  = hport($self->getNum());
  $self->{ports}{https} = hsport($self->getNum());
  $self->{ports}{tcp}   = tport($self->getNum());
  $self->{ports}{udp}   = uport($self->getNum());
}

sub setupSolsmDir($) {
  my ($solsmdir) = @_;

  my $objdirRelative = $Solace::Sm::Env::objdirRelative;

  ## There is a hidden .sm dir in $HOME, which is shared between all
  ## simulators regardless of where their individual solsm dir is.
  mkdir("$ENV{HOME}" . "/.sm");

  ## Only write the SolaceStartup.txt file if we create the router
  ## directory.  That way edits after the fact will be preserved.
  ##
  if (mkdir("$solsmdir/sm")) {
    ## Create common SolaceStartup.txt file.
    open(FD, ">$solsmdir/sm/SolaceStartup.txt");
    print FD "
[entry]
[start]
[run]
$objdirRelative/bin/dataplane -h \$HPORT -l WARN -d \$DIR
$objdirRelative/bin/controlplane -h \$HPORT -l WARN -d \$DIR
$objdirRelative/bin/smrp -l WARN -d \$DIR
$objdirRelative/bin/mgmtplane -V -l WARN -d \$DIR --semp-port \$HPORT --semp-ssl-port \$HSPORT \${NAME:+--hostname} \$NAME
$objdirRelative/bin/xmlmanager -l WARN -d \$DIR
$objdirRelative/bin/solsnmp -l WARN -d \$DIR
$objdirRelative/bin/trmmanager -l WARN -d \$DIR
$objdirRelative/bin/msgbusadapter -l WARN -d \$DIR
$objdirRelative/bin/solcachemgr -l WARN -d \$DIR
$objdirRelative/bin/dnsmanager -l WARN -d \$DIR
$objdirRelative/bin/watchdog -k -l WARN -d \$DIR

[SIGRTMIN+1]
\$CVSWD/solcbr/firmware/3206/dataplane-linux -d \$DIR &
[reap]
/bin/sleep 1
[finish]
pkill -P \$PPID dataplane-linux
[exit]
[shutdown:reboot]
[shutdown:power]
    ";
    close(FD);
  }
}

my $hport_base  = 10000;
my $hsport_base = 30000;
my $tport_base  = 20000;
my $uport_base  = $tport_base;
my $username    = $ENV{"USER"};
my $uid = (getpwnam($username))[2];

sub hport($) {
  return $hport_base + ($uid % 1000)*10 + $_[0]*2;
}
sub hsport($) {
  return $hsport_base + ($uid % 1000)*10 + $_[0]*2;
}
sub tport($) {
  return $tport_base + ($uid % 1000)*10 + $_[0]*5;
}
sub uport($) {
  return $uport_base + ($uid % 1000)*10 + $_[0]*2;
}

1;


