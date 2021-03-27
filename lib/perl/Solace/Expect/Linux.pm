package Solace::Expect::Linux;

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
sub new {
  my $class = shift;
  my %args = @_;

  my $self = {};

  $self->{router}          = $args{router};
  $self->{ip}              = $args{ip};
  $self->{log_stdout}      = $args{log_stdout} || 0;
  $self->{use_serial}      = $args{use_serial} || 0;
  $self->{takeover_serial} = $args{takeover_serial} || 0;
  $self->{debug}           = $args{debug}      || 0;
  $self->{verbose}         = $args{verbose}    || $args{debug} || 0;
  $self->{timeout}         = $args{timeout}    || 2;
  $self->{die_on_err}      = defined $args{die_on_err} ? $args{die_on_err} : 1;

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

  print "Connecting to Linux on $self->{router}...\n" if $self->{verbose};

  my $debug = $self->{debug} || $self->{verbose};

  my $amRoot = 0;
  my $amSysadmin = 0;

  if ($self->{router} =~ /^sm:(\d+)/) {
    croak("Linux connections are not supported on the simulator");
    # Solace::Expect::Generic::spawnLocalShell($exp, $debug);
  }
  elsif ($self->{ip} =~ /^127\.0\.0\./) {
    Solace::Expect::Generic::spawnLocalShell(\$exp, $debug);
  }
  else {
    my $result;
    if ($self->{use_serial}) {
      $result = Solace::Expect::Generic::spawnLabConsoleAndLogin("$self->{router}",
                                                                 "support",
                                                                 "support",
                                                                 \$exp, $debug,
                                                                 '$ ', $self->{takeover_serial});
      if (!defined($result)) {
        if ($self->{die_on_err}) { 
          die("Unable to connect to server $self->{router} over serial port");
        } else { 
          return -1;
        }
      }
      $exp->clear_accum();
    }
    else {


      $result = Solace::Expect::Generic::spawnSshAndLogin("sysadmin\@$self->{ip}",
                                                          "sysadmin",
                                                          \$exp, $debug,
                                                                 '$ ');

      if (!defined $result || $result != 0) {
          $result = Solace::Expect::Generic::spawnSshAndLogin("support\@$self->{ip}",
                                                              "support",
                                                              \$exp, $debug,
                                                                     '$ ');
      }
      else {
          $amSysadmin = 1;
      }

      if (!defined $result || $result != 0) {
        # Failed to login - this could be caused by attempting to log into a perf host
        # Try again with a root login
        $result = Solace::Expect::Generic::spawnSshAndLogin("root\@$self->{ip}",
                                                            "solace1",
                                                            \$exp, $debug,
                                                            ['-re', "(\]|~)# "]);
        if (!defined $result || $result != 0) {
          if ($self->{die_on_err}) { 
            die("Unable to connect to server $self->{router} ($self->{ip})");
          } else { 
            return -1;
          }
        }
        $amRoot = 1;
        $exp->log_stdout($debug?1:0);
        $exp->raw_pty(1);
        $exp->send("stty -echo\r");
        $exp->expect($timeout->{conn}->{timeout} || 10, ']$', ']# ', '~#');
        $exp->clear_accum();
        $exp->send("bash\r");
        $exp->expect($timeout->{conn}->{timeout} || 10, ']$', ']# ', '~#');
        $exp->clear_accum();
      }

    }

  }
  
  # $exp->log_file("/home/efunnekotter/tmp/expect.log");
  $exp->log_stdout($debug?1:0);
  $exp->send("source /usr/solace/loads/currentload/scripts/solbashrc\r");
  $exp->expect(10, ']$', ']# ', "\n% ", "RRS>: ", '~#');
  $exp->clear_accum();

  if ($amSysadmin) {
    $exp->send("docker exec -it solace bash\r");
    $exp->expect(2, ']$', ']# ', '~#');
    $exp->clear_accum();
    $exp->raw_pty(1);
    $exp->send("stty -echo\r");
    $exp->expect($timeout->{conn}->{timeout} || 10, ']$', ']# ', '~#');
    $exp->clear_accum();
  }
  elsif (!$amRoot) {
    $exp->send("sudo su -\r");


    $exp->expect(2,
                 ['-re', 'assword( for root)?:', sub { my $self = shift;
                                                       $self->send("solace1\r");
                                                       exp_continue; }],
                 ']#');
    $exp->clear_accum();
  }

  $exp->send("export PS1='<RRS>: '\r");
  $exp->expect(2, '-re', '^<RRS>: ');
  $exp->clear_accum();
  $exp->send("unset PROMPT_COMMAND\r");
  $exp->expect(2, '-re', '^<RRS>: ');
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
  print "\nSending '$cmd'\n" if $self->{debug};
  $self->{exp}->send("$cmd\r");

  while(1) {
    my $match = $self->{exp}->expect($timeout,
                                     ['-re', "<RRS>: "],
                                     ['-re', "]# \$"],
                                     ['-re', "assword:\\s*"],
                                     ['-re', "connecting \\(yes/no\\)\\?\\s*"],
                                    );

    if (!defined $match) {
      print "Request timed out on command: $cmd\n" if $self->{verbose};
      $@ = "Linux request timed out on command: $cmd (timeout: ${timeout}s)";
      return undef;
    }
    elsif ($match == 1 || $match == 2) {
      last;
    }
    elsif ($match == 3) {
      $self->{exp}->send("y\r");
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
