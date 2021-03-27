package Solace::Expect::Shell;

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
#   username => <cli login username>,
#   password => <cli login password>,
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

  print "\n\nEstablishing shell on $self->{router}...\n" if $self->{verbose};

  my $debug = $self->{debug} || $self->{verbose};

  my $result;
  if ($self->{username} eq "root") {
    $result = Solace::Expect::Generic::spawnSshAndLogin("$self->{username}\@$self->{ip}",
							$self->{password},
							\$exp, $debug,
							']# ');
  } else {
    if (defined $self->{keyfile}) {
      $result = Solace::Expect::Generic::spawnSshWithKeyfile("$self->{username}\@$self->{ip}",
							     $self->{keyfile},
							     \$exp, $debug,
							     ']$ ');
    } else {
      $result = Solace::Expect::Generic::spawnSshAndLogin("$self->{username}\@$self->{ip}",
							  $self->{password},
							  \$exp, $debug,
							  ']$ ');
    }
  }

  my $amSysadmin = 0;

  if ($self->{username} eq "sysadmin") {
      $amSysadmin = 1;
  }

  if (not defined $result) { return undef; }

  $exp->log_stdout($debug?1:0);
  $exp->raw_pty(1);
  $exp->send("stty -echo\r");
  $exp->expect(10, ']$', ']# ');
  $exp->clear_accum();
  if ($amSysadmin == 1) {
      $exp->send("docker exec -it solace bash\r");
  } else {
      $exp->send("bash\r");
  }
  $exp->expect(10, ']$', ']# ');
  $exp->clear_accum();

  $exp->log_stdout($debug?1:0);
  $exp->send("source /usr/solace/loads/currentload/scripts/solbashrc\r");
  $exp->expect(10, ']$', ']# ', "\n% ");
  $exp->clear_accum();

  $exp->send("export PS1='<RRS>: '\r");
  $exp->expect(2, '<RRS>: ');
  $exp->clear_accum();
  $exp->send("unset PROMPT_COMMAND\r");
  $exp->expect(2, '<RRS>: ');
  $exp->clear_accum();
  $self->{exp} = $exp;

} # connect #



########################################
# send(<command>, [timeout = 10s])
#
# 
sub send {
  my ($self, $cmd, $timeout) = @_;

  $timeout ||= $self->{timeout};

  $cmd =~ s/[\n\r]//g;
  print "\nSending '$cmd'\n" if $self->{debug};
  $self->{exp}->send("$cmd\r");

  while(1) {
    my $match = $self->{exp}->expect($timeout,
                                     "<RRS>: ",
                                     ['-re', "]# \$"],
                                     ['-re', "assword:\\s*"],
                                     ['-re', "connecting \\(yes/no\\)\\?\\s*"],
                                    );

    if (!defined $match) {
      print "Request timed out on command: $cmd\n" if $self->{verbose};
      $@ = "Shell request timed out on command: $cmd (timeout: ${timeout}s)";
      return undef;
    } elsif ($match == 1 || $match == 2 || $match == 3) {
      last;
    } elsif ($match == 4) {
      $self->{exp}->send("y\r");
    } else {
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
