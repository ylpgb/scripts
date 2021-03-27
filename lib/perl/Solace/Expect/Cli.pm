package Solace::Expect::Cli;

use strict;
use warnings;
use Data::Dumper;



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
  $self->{username}   = $args{username};
  $self->{password}   = $args{password};
  $self->{timeout}    = $args{timeout}    || 2;

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

  print "Connecting to the CLI on $self->{router}...\n" if $self->{verbose};

  my $sim = 0;
  if ($self->{router} =~ /^sm:(\d+)/) {
    Solace::Expect::Generic::spawnSimulator(\$exp, $self->{debug} || $self->{verbose}, 
                                            '> ', 
                                            "sm router cli $1");
    $sim = 1;
  }
  else {

    my $result = Solace::Expect::Generic::spawnSshAndLogin("$self->{username}\@$self->{ip}",
							   $self->{password}, \$exp,
							   $self->{debug} || $self->{verbose},
							   '> ');
    if (not defined $result) { 
      $@ = "Login failed or timed out.";
      return undef; 
    }
  }

  if ($sim) {
    $exp->send("exit\r");
    $exp->expect(10, "> ");
    $exp->clear_accum();
    $exp->send("exit\r");
    $exp->expect(10, "> ");
    $exp->clear_accum();
  }

  $exp->clear_accum();
  $exp->send("no alarm-display\r");
  $exp->expect(10, ['-re', "[^\-]> "]);
  $exp->clear_accum();
  $exp->send("no paging\r");
  $exp->expect(10, "> ");
  $exp->clear_accum();

  $self->{exp} = $exp;
  
  return $self;

}


########################################
# send(<command>, [timeout = 10s])
#
# 
sub send {
  my ($self, $cmd, $timeout) = @_;

  $timeout ||= $self->{timeout};

  $cmd =~ s/[\n\r]//g;
  $self->{exp}->send("$cmd\r");

  my ($match, $error, $matchStr, $before, $after);
  while(1) {
    ($match, $error, $matchStr, $before, $after) = $self->{exp}->expect($timeout,
                             ['-re', "[0-9\\)a-zA-Z]#[ ]+\$"],
                             ['-re', "[^\\s<]+[0-9a-zA-Z\\)]> \$"],
                             ['-re', "^[^\\s<]+[0-9a-zA-Z\\)]> \$"],
                             "(y/n)?");
    if (!defined $match) {
      print "Request timed out on command: $cmd\nReceived up to now: " . $self->{exp}->before() ."\n" if $self->{verbose};
      $@ = "CLI request timed out on command: $cmd (timeout: ${timeout}s)";
      return undef;
    }
    elsif ($match == 1) {
      $before =~ s/^[^\n]+\n//;
      return "" if ($before !~ /\n/);
      $before =~ s/\n[^\n]+$/\n/;
      last;
    }
    elsif ($match == 2 || $match == 3) {
      $before =~ s/^[^\n]+\n//;
      last;
    }
    elsif ($match == 4) {
      $self->{exp}->send("y\r");
    }
    else {
      return undef;
    }

  }

  return "" if ($before !~ /\n/);

  return $before;
  
}


sub close {
  my ($self) = @_;

  $self->{exp}->close();

  $self->{exp} = undef;

}


1;
