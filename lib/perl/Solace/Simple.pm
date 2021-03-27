#############################################################################
##
## Solace::Simple
##
## This module will try to make it as simple as possible to interact with
## CLI, soldebug and the linux prompt on a Solace router.  For more 
## advanced usage, users should use Solace::Expect directly.
##
#############################################################################

package Solace::Simple;

use strict;
use warnings;
use Data::Dumper;
use Solace::Expect;
use Solace::Semp;
use Expect;
use Carp;


# new - create a new object to interact with a specific router
#
# Parameters:
#   o router          - specify the router to connect to (required)
#   o dieOnError      - will check CLI results for known errors and die (default: 1)
#   o warnOnError     - will check CLI results for known errors and print a warning (default: 1)
#   o debug           - dump debug info (default: 0)
#   o verbose         - print out more status info (default: 0)
#   o reissueOnExists - if a CLI create command fails with 'already exists', the command
#                       will automatically be reissued without the 'create' keyword (default: 1)
sub new {
  my $class = shift;
  my %args  = @_;

  map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{router};

  my %self = (router          => $args{router},
              sempPort        => $args{sempPort},
              useSerialPort   => $args{useSerialPort},
              takeoverSerial  => $args{takeoverSerial},
              dieOnError      => defined($args{dieOnError})      ? $args{dieOnError}      : 1,
              warnOnError     => defined($args{warnOnError})     ? $args{warnOnError}     : 1,
              debug           => defined($args{debug})           ? $args{debug}           : 0,
              verbose         => defined($args{verbose})         ? $args{verbose}         : 0,
              timeout         => defined($args{timeout})         ? $args{timeout}         : 10,
              reissueOnExists => defined($args{reissueOnExists}) ? $args{reissueOnExists} : 1,
             );

  bless(\%self, $class);

  return \%self;

}


# Catch all getter/setter
sub AUTOLOAD {
  my ($self, $value) = @_;
  our $AUTOLOAD;

  if (grep {"Solace::Simple::$_" eq $AUTOLOAD}  qw{debug verbose timeout reissueOnExists dieOnError warnOnError sempPort}) {
    my ($attr) = ($AUTOLOAD =~ /(\w*)$/);
    $self->{$attr} = $value if defined $value;
    return $self->{$attr};
  }
  else {
    croak("Undefined method called: $AUTOLOAD");
  }

}


sub getSession {
  my ($self, $type, %options) = @_;

  if (!defined $self->{$type}) {
    $self->{$type} = new Solace::Expect(router          => $self->{router},
                                        die_on_err      => $self->{dieOnError},
                                        use_serial      => $self->{useSerialPort},
                                        takeover_serial => $self->{takeoverSerial},
                                        type            => $type,
                                        debug           => $self->{debug},
                                        log_stdout      => $self->{debug},
                                        semp_port       => $self->{sempPort},
                                        %options);
    if (!defined($self->{$type})) {
      carp("Failed to create session to $self->{router}");
      return undef;
    }
    $self->{$type} = $self->{$type}->connect();
    if (!defined $self->{$type} || $self->{$type} == -1) {
      $self->{$type} = undef;
      if (!defined($self->{dieOnError}) || $self->{dieOnError}) {
        croak("Failed to create $type session on router $self->{router}");
      }
      else {
        # carp("Failed to create $type session on router $self->{router}");
        return undef;
      }
    }
  }
  return $self->{$type};
}

sub connect {
  my ($self, $type, %options) = @_;

  my $session = $self->getSession($type, %options);
  
  return defined($session) ? 1 : 0;
}

# Send a CLI command
sub cli {
  my ($self, $cmd, $timeout) = @_;

  $timeout ||= $self->{timeout};

  my $s = $self->getSession('cli');
  if (!defined($s)) {
    if (!defined($self->{dieOnError}) || $self->{dieOnError}) {
      die "Failed to create CLI session";
    }
    else {
      return undef;
    }
  }
  
  my $result = $s->send($cmd, $timeout);

  if (defined $result && 
      $self->{reissueOnExists} && 
      $result =~ /already exists/i && 
      $cmd =~ /^\s*create\s/) {

    $cmd =~ s/\s*create\s(.*)/$1/;
    $result = $s->send($cmd, $timeout);

  }
  if (!defined($result)) {
    print "Command $cmd timed out after ${timeout}s\n";
  }
  else {
    if ($result =~ /^ERROR: / ||
        $result =~ /Invalid command input/) {
      if ($self->{dieOnError}) {
        croak("Received error result on CLI command: $cmd.\n\n$result\n");
      }
      elsif ($self->{warnOnError}) {
        carp("Received error result on CLI command: $cmd.\n\n$result\n");
      }
    }
  }
  return $result;
}

# Send a soldebug command
sub soldebug {
  my ($self, $cmd, $timeout) = @_;
  $timeout ||= $self->{timeout};
  my $s = $self->getSession('soldebug');
  if (!defined($s)) {
    if (!defined($self->{dieOnError}) || $self->{dieOnError}) {
      die "Failed to create soldebug session";
    }
    else {
      return undef;
    }
  }
  return $s->send($cmd, $timeout);
}

# Send a linux command
sub linux {
  my ($self, $cmd, $timeout) = @_;
  $timeout ||= $self->{timeout};
  my $s = $self->getSession('linux');
  if (!defined($s)) {
    if (!defined($self->{dieOnError}) || $self->{dieOnError}) {
      die "Failed to create linux session" if !defined($s);
    }
    else {
      return undef;
    }
  }
  return $s->send($cmd, $timeout);
}

# Send a semp command
sub semp {
  my ($self, $cmd, $responseType) = @_;
  my $s = $self->getSession('semp');
  if (!defined($s)) {
    if (!defined($self->{dieOnError}) || $self->{dieOnError}) {
      die "Failed to create SEMP session" if !defined($s);
    }
    else {
      return undef;
    }
  }
  return $s->send(cli => $cmd,
                  responseType => $responseType);
}

sub DESTROY {

}

1;
