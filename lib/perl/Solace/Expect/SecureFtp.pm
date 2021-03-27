package Solace::Expect::SecureFtp;

use strict;
use warnings;
use Data::Dumper;
use Solace::Expect::Generic;
use Expect;
use Carp;

# 
# Constructor
#
# Options:
#   router => <router-name>,
#   log_stdout => <0|1>,
#   debug => <0|1>,
#   verbose => <0|1>,
#   username => <sftp login username>,
#   password => <sftp login password>,
#   keyfile => <ssh keyfile name>,
sub new {
  my $class = shift;
  my %args = @_;

  my $self = {};

  $self->{router}     = $args{router};
  $self->{ip}         = $args{ip};
  $self->{log_stdout} = $args{log_stdout} || 0;
  $self->{debug}      = $args{debug}      || 0;
  $self->{verbose}    = $args{verbose}    || $args{debug} || 0;
  $self->{username}   = $args{username};
  $self->{password}   = $args{password};
  $self->{keyfile}    = $args{keyfile};
  $self->{timeout}    = 200;

  if (!defined $self->{router}) {
    die "'router' must be specified when creating a Solace::Expect session";
  }
  if (!defined $self->{ip}) {
    die "'ip' must be specified when creating a Solace::Expect session";
  }

  ## Private class data access.

  bless($self, $class);

  return $self;
}




sub connect($) {
  my ($self, $timeout) = @_;
  my $exp;

  print "\n\nEstablishing SFTP session on $self->{router}...\n" if $self->{verbose};

  my $debug = $self->{debug} || $self->{verbose};

  my $result;
  if (defined $self->{keyfile}) {
    $result = Solace::Expect::Generic::spawnSftpWithKeyfile("$self->{username}\@$self->{ip}",
                                                            $self->{keyfile},
                                                            \$exp, $debug,
                                                            'sftp> ');
  } else {
    $result = Solace::Expect::Generic::spawnSftpAndLogin("$self->{username}\@$self->{ip}",
                                                         $self->{password},
                                                         \$exp, $debug,
                                                         'sftp> ');
  }

  if (not defined $result) { return undef; }

  $exp->clear_accum();
  $self->{exp} = $exp;

  return $self;

} # connect #



########################################
# send(<command>, [timeout = 10s])
#
# 
sub send {
  my ($self, $cmd, $timeout) = @_;

  $timeout ||= $self->{timeout};

  $cmd =~ s/[\n\r]//g;
  print "\nSending '$cmd timeout $timeout'\n" if $self->{debug};
  $self->{exp}->send("$cmd\n");

  while(1) {
    my $match = $self->{exp}->expect($timeout,
                                     "sftp> ",
                                     ['-re', "assword:\\s*"],
                                     ['-re', "connecting \\(yes/no\\)\\?\\s*"],
                                    );

    if (!defined $match) {
      print "Request timed out on command: $cmd\n" if $self->{verbose};
      $@ = "Request timed out on command: $cmd (timeout: ${timeout}s)";
      return undef;
    }
    elsif ($match == 1 || $match == 2) {
      last;
    }
    elsif ($match == 3) {
      $self->{exp}->send("yes\r");
    }
    else {
      return undef;
    }

  }

  my $result = $self->{exp}->before();

  return $result;
  
}


sub close {
  my ($self) = @_;
  $self->{exp}->close();
  $self->{exp} = undef;
}

1;
