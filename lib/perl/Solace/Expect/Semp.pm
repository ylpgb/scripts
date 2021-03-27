package Solace::Expect::Semp;

use strict;
use warnings;
use Data::Dumper;
#use XML::Simple;
use Solace::Semp;
use File::Temp qw/ tempfile /;

  
# 
# Constructor
#
# Options:
#   router => <router-name>,
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
  $self->{port}       = $args{port};
  $self->{log_stdout} = $args{log_stdout} || 0;
  $self->{debug}      = $args{debug}      || 0;
  $self->{verbose}    = $args{verbose}    || $args{debug} || 0;
  $self->{username}   = $args{username}   || "admin";
  $self->{password}   = $args{password}   || "admin";
  $self->{version}    = $args{version};
  $self->{indent}     = $args{indent};

  if (!defined $self->{router}) {
    die "'router' must be specified when creating a Solace::Expect session";
  }
  if (!defined $self->{ip}) {
    die "'ip' must be specified when creating a Solace::Expect session";
  }

  my $customTransport;
  if ($self->{router} =~ /^sm:(\d+)/) {
    $customTransport = sub {$self->sendSimSemp(@_);};
  }

  $self->{semp} = Solace::Semp->new(customTransport => $customTransport,
                                    debug           => $self->{debug},
                                    version         => $self->{version},
                                    port            => $self->{port},
                                    hostname        => $self->{router},
                                    username        => $self->{username},
                                    password        => $self->{password},
                                    indent          => $self->{indent});

  ## Private class data access.

  bless($self, $class);

  return $self;
}


# Callback from the Solace::Semp module - this will
# use the 'sm' tools to send and receive SEMP instead
# of going directly
sub sendSimSemp {
  my ($self, $xml) = @_;
  
  my ($fh, $filename) = tempfile();

  print $fh $xml;

  close($fh);

  my ($num) = ($self->{router} =~ /:(\d+)/);
  my $res = `sm debug semp $num --no-validate --file=$filename`;
  unlink($filename);

  return $res;

}


# Send SEMP to the router - this will take either a CLI command or
# a properly formed XML SEMP message. The underlying module will sort it out
# input arguments: <cli | xml> [responseType]
#   cli => 'cli command string' 
#   xml => 'SEMP in XML'
#   responseType => 'perl or xml'
sub send {
  my ($self, @args) = @_;
  return $self->{semp}->send(@args);
}

sub connect {
  my ($self) = @_;
  return $self;
}

1;
