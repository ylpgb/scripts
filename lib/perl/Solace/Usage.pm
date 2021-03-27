##
## Solace::Usage
##
## This is a simple perl module that will send script usage
## information to a central server
##
## Copyright Solace Systems 2011
##

package Solace::Usage;

sub logUsage {
  my ($name, $extra) = @_;
  use IO::Socket; 
  my $handle = IO::Socket::INET->new(Proto => 'udp') or return;
  my $ipaddr = inet_aton("dev180") || return; 
  my $portaddr = sockaddr_in(33333, $ipaddr) || return; 
  # chomp(my $me    = `whoami`);
  chomp(my $where = `hostname`);
  my $scriptName = $name || $0;
  $scriptName =~ s/^.*\///;
  my $msg;
  # $msg .= "USER: '$me', ";
  # $msg .= "HOST: '$where', ";
  # Just send the Script name - no need to be too nosey
  $msg .= "SCRIPT: '$scriptName', ";
  $msg .= "EXTRA: '$extra'" if defined($extra);
  my $rc = send($handle, $msg, 0, $portaddr);
}

1;
