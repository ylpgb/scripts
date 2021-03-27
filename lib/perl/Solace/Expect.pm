package Solace::Expect;

use strict;
use warnings;
use Data::Dumper;
use Expect;
use Carp;
use Solace::Expect::Cli;
use Solace::Expect::Soldebug;
use Solace::Expect::Linux;
use Solace::Expect::Shell;
use Solace::Expect::SecureFtp;
use Solace::Expect::Semp;

# 
# Constructor
#
# Options:
#   router => <router-name>,
#   type => <cli | soldebug | linux>,
#   log_stdout => <0|1>,
#   debug => <0|1>,
#   verbose => <0|1>,
#   username => <cli login username>,
#   password => <cli login password>,
#   keyfile => <ssh keyfile name>,
sub new {
  my $class = shift;
  my %args = @_;

  my $self = {};

  $self->{router}          = $args{router};
  $self->{type}            = $args{type};
  $self->{semp_port}       = $args{semp_port};
  $self->{log_stdout}      = $args{log_stdout} || 0;
  $self->{use_serial}      = $args{use_serial} || 0;
  $self->{takeover_serial} = $args{takeover_serial} || 0;
  $self->{debug}           = $args{debug}      || 0;
  $self->{verbose}         = $args{verbose}    || $args{debug} || 0;
  $self->{username}        = $args{username};
  $self->{password}        = $args{password};
  $self->{keyfile}         = $args{keyfile};
  $self->{timeout}         = $args{timeout};
  $self->{die_on_err}      = defined $args{die_on_err} ? $args{die_on_err} : 1;

  if (!defined $self->{username}) {
    $self->{username} = "admin";
  }
  if (!defined $self->{password}) {
    $self->{password} = "admin";
  }

  if (!defined $self->{type}) {
    die "'type' (cli | soldebug | linux) must be specified when creating a Solace::Expect session";
  }

  if (!defined $self->{router}) {
    die "'router' asdas must be specified when creating a Solace::Expect session";
  }

  my ($name, $ip) = getHostnameAndIp($self->{router});

  if (!defined($ip)) {
    carp("Failed hostname lookup for $self->{router}");
    return undef;
  }

  bless($self, $class);

  if ($self->{type} eq "cli") {
    $self->{conn} = new Solace::Expect::Cli(router     => $self->{router},
                                            ip         => $ip,
                                            log_stdout => $self->{log_stdout},
                                            debug      => $self->{debug},
                                            verbose    => $self->{verbose},
					    username   => $self->{username},
					    password   => $self->{password},
                                            die_on_err => $self->{die_on_err});
  }
  elsif ($self->{type} eq "soldebug") {
    $self->{conn} = new Solace::Expect::Soldebug(router     => $self->{router},
                                                 ip         => $ip,
                                                 log_stdout => $self->{log_stdout},
                                                 debug      => $self->{debug},
                                                 timeout    => $self->{timeout},
                                                 verbose    => $self->{verbose},
                                                 die_on_err => $self->{die_on_err});
  }
  elsif ($self->{type} eq "linux") {
    $self->{conn} = new Solace::Expect::Linux(router     => $self->{router},
                                              ip         => $ip,
                                              use_serial => $self->{use_serial},
                                              log_stdout => $self->{log_stdout},
                                              timeout    => $self->{timeout},
                                              debug      => $self->{debug},
                                              verbose    => $self->{verbose},
                                              die_on_err => $self->{die_on_err});
  }
  elsif ($self->{type} eq "shell") {
    $self->{conn} = new Solace::Expect::Shell(router     => $self->{router},
                                              ip         => $ip,
                                              use_serial => $self->{use_serial},
                                              log_stdout => $self->{log_stdout},
                                              debug      => $self->{debug},
                                              verbose    => $self->{verbose},
					      username   => $self->{username},
					      keyfile    => $self->{keyfile},
					      password   => $self->{password},
                                              die_on_err => $self->{die_on_err});
  }
  elsif ($self->{type} eq "sftp") {
    $self->{conn} = new Solace::Expect::SecureFtp(router     => $self->{router},
						  ip         => $ip,
						  log_stdout => $self->{log_stdout},
						  debug      => $self->{debug},
						  verbose    => $self->{verbose},
						  username   => $self->{username},
						  keyfile    => $self->{keyfile},
						  password   => $self->{password},
                                                  die_on_err => $self->{die_on_err});
  }
  elsif ($self->{type} eq "semp") {
    $self->{conn} = new Solace::Expect::Semp(version    => $args{version},
                                             router     => $self->{router},
                                             ip         => $ip,
                                             port       => $self->{semp_port},
                                             debug      => $self->{debug},
                                             verbose    => $self->{verbose},
                                             username   => $self->{username},
                                             password   => $self->{password},
                                             semp_port  => $self->{semp_port},
                                             die_on_err => $self->{die_on_err});
  }

  ## Private class data access.

  return $self;
}


sub getHostnameAndIp {
  my ($name) = @_;

  my (@bytes, @octets,
    $packedaddr,
    $raw_addr,
    $host_name,
    $ip
  );

  if($name =~ /sm:\d+/) {
    $ip = "127.0.0.1";
    $host_name = $name;
  }
  elsif($name =~ /[a-zA-Z]/g) {
    $raw_addr = (gethostbyname($name))[4];
    if (!defined($raw_addr)) {
      return (undef, undef);
    }
    @octets = unpack("C4", $raw_addr);
    $host_name = $name;
    $ip = join(".", @octets);
  } 
  else {
    $name =~ s/:\d+$//;
    @bytes = split(/\./, $name);
    map {if ($_ > 255) { Fatal("Invalid IP address: $name")}} @bytes;
    $packedaddr = pack("C4",@bytes);
    $ip = $name;
    $host_name = (gethostbyaddr($packedaddr, 2))[0];
  }

  return($host_name, $ip);

} # getHostnameAndIp #


sub connect($) {
  my ($self, $timeout) = @_;
  return $self->{conn}->connect(@_);
}


sub send {
  my $self = shift;
  return $self->{conn}->send(@_);
}


sub close {
  my ($self) = @_;
  return $self->{conn}->close();
}


1;
