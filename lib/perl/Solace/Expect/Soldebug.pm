package Solace::Expect::Soldebug;

use strict;
use warnings;
use Data::Dumper;
use Solace::Expect::Generic;


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

  $self->{router}     = $args{router};
  $self->{ip}         = $args{ip};
  $self->{log_stdout} = $args{log_stdout} || 0;
  $self->{use_serial} = $args{use_serial} || 0;
  $self->{debug}      = $args{debug}      || 0;
  $self->{verbose}    = $args{verbose}    || $args{debug} || 0;
  $self->{timeout}    = $args{timeout}    || 2;

  if (!defined $self->{router}) {
    die "'router' must be specified when creating a Solace::Expect session";
  }

  ## Private class data access.

  bless($self, $class);

  return $self;
}

sub connect($) {
  my ($self, $timeout) = @_;
  my $exp;
  my $amSysadmin = 0;

  print "Connecting to the soldebug on $self->{router}...\n" if $self->{verbose};

  if ($self->{router} =~ /^sm:(\d+)/) {
    Solace::Expect::Generic::spawnSimulator(\$exp, $self->{debug} || $self->{verbose}, 
                                            '> ',
                                            "sm debug soldebug $1");
  }
  elsif ($self->{ip} =~ /^127\.0\.0\./) {
    Solace::Expect::Generic::spawnLocalShell(\$exp, $self->{debug} || $self->{verbose});
  }
  else {
    my $result = Solace::Expect::Generic::spawnSshAndLogin("sysadmin\@".$self->{router},
                                                           "sysadmin", \$exp,  
                                                           $self->{debug} || $self->{verbose}, '$ ');

    if (not defined $result || $result != 0) {
        $result = Solace::Expect::Generic::spawnSshAndLogin("support\@".$self->{router},
                                                            "support", \$exp,
                                                            $self->{debug} || $self->{verbose}, '$ ');
    }
    else {
        $amSysadmin = 1;
    }


    if (not defined $result || $result != 0) { 
      $@ = "Login failed or timed out.";
      return undef; 
    }
  }
  

  $exp->clear_accum();
  $exp->log_stdout($self->{log_stdout});
  if ($amSysadmin == 1) {
      $exp->send("docker exec -it solace /usr/sw/loads/currentload/bin/soldebug\r");
  }
  else {
      $exp->send("/usr/sw/loads/currentload/bin/soldebug\r");
  }
  my $match = $exp->expect(10, ['-re', '\(safe\)-> '], ['-re', '-> ']);
  if (!defined($match)) {
    print "Failed to connect to soldebug: " . $exp->before() . "\n" if $self->{debug};
    return undef;
  }
  $exp->clear_accum();
  $exp->send(":unsafe\r");
  $exp->expect(10, ['-re', '\n-> ']);
  $exp->clear_accum();

  $self->{exp} = $exp;

  return $self;

} # SoldebugConnect #



########################################
# send(<command>, [timeout = 10s])
#
# 
sub send {
  my ($self, $cmd, $timeout) = @_;

  $timeout ||= $self->{timeout};

  $cmd =~ s/[\n\r]//g;
  $self->{exp}->send("$cmd\r");

  while(1) {
    my $match = $self->{exp}->expect($timeout,
                                     ['-re', "\\-> \$"]
                                    );

    if (!defined $match) {
      print "Request timed out on command: $cmd\n" if $self->{verbose};
      $@ = "Soldebug request timeout on command: $cmd (timeout: ${timeout}s)";
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
  $result =~ s/^[^\n]+\n//;
  return "" if ($result !~ /\n/);
  $result =~ s/\n[^\n]+$/\n/;

  return $result;
  
}


sub close {
  my ($self) = @_;

  $self->{exp}->close();

  $self->{exp} = undef;

}


1;
