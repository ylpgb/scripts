package Solace::Sm::Prod::Router;

use warnings;
use base Solace::Sm::Router;

sub isDev() {
  my $self = shift();
  return 0;
}

sub getDir() {
  my $self = shift();
  return "/usr/solace";
}

sub getMsgBbIp() {
  my $self = shift();

  my $ip = $self->getMgmtIp();

  ## Convert subnet based on lab convention.
  my %subnetMap = (128 => 160,
		   129 => 164);
  my ($a,$b,$c,$d) = split(/\./, $ip);
  $ip = join(".", $a, $b, $subnetMap{$c}, $d);
  return $ip;
}

sub runOnHost($) {
  my $self = shift();
  my $cmd = shift();
  return `ssh root\@$self->{host} "$cmd"`;
}

sub execOnHost($) {
  my $self = shift();
  my $cmd = shift();
  exec("ssh root\@$self->{host} -t $cmd");
}

sub copyFileToDir($$) {
  my $self = shift();
  my $localFile = shift();
  my $remoteFile = $self->getDir() . "/" . shift();
  return `scp $localFile root\@$self->{host}:$remoteFile`;
}

sub doInit() {
  my $self = shift();

  ## Setup for password-less login.  Non-zero return indicates an
  ## error.
  my $rc = system("addkeyto $self->{host} >& /dev/null");
  if ($rc) {
    die("Failed addkeyto for $self->{host}: $rc\n");
  }

  ## Choose our ports.
  $self->{ports}{http} = 80;
  $self->{ports}{tcp}  = 55555;
  $self->{ports}{udp}  = 55555;
}

1;


