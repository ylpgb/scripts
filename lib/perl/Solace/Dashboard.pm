#############################################################################
##
## Solace::Dashboard
##
## This module will get dashboard information from the Solace Wiki
##
#############################################################################

package Solace::Dashboard;

use strict;
use warnings;
use Data::Dumper;
use Carp;
use DateTime;
use Date::Parse;
use HTML::TableExtract;
use Solace::Wiki;

# new - create a new object to interact with the wiki
#
# Parameters:
#   o url             - base URL of the wiki
sub new {
  my $class = shift;
  my %args  = @_;

  # map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{url};

  # Ugly in a module to default to such a specific string, but it will be very
  # handy if the URL changes and we don't have to update a large number of scripts
  $args{url} = 'http://192.168.1.202:8080/solportal' if !defined $args{url};
  
  if ($args{url} !~ /Wiki.jsp/) {
    if ($args{url} !~ /\/\s*$/) {
      $args{url} .= "/Wiki.jsp";
    }
    else {
      $args{url} .= "Wiki.jsp";
    }
  }
  
  $args{url} =~ s/\?.*//;

  my %self = (url => $args{url});

  $self{wiki} = new Solace::Wiki(url => $args{url});

  if (!defined($self{wiki})) {
    croak("Failed to create a wiki object");
  }

  bless(\%self, $class);

  return \%self;

}

sub DESTROY {
    my ($self) = @_;
}

sub getAllDashboards {
  my ($self, $minIteration) = @_;
  my $index = $self->{wiki}->getPage("PageIndex");
  my @pages = ($index =~ /\?page=([^'"]+)/g);
  @pages = grep(/dashboard/i, @pages);

  if ($minIteration) {
    my @temp;
    foreach my $page (@pages) {
      if ($page =~ /[dD](\d+)_/) {
        if ($1 >= $minIteration) {
          push(@temp, $page);
        }
      }
      else {
        push(@temp, $page);
      }
    }
  }

  $self->{dashboards}   = \@pages;
  $self->{minIteration} = $minIteration;

  if (wantarray) {
    $self->getAllInfo();
    my $first = 0xffffffff;
    my $last  = 0;
    map {$last = $self->{info}{$_}{end}{best} if $self->{info}{$_}{end}{best} > $last} keys(%{$self->{info}});
    map {$first = $self->{info}{$_}{start}{best} if $self->{info}{$_}{start}{best} < $first} keys(%{$self->{info}});
    @pages = sort(keys(%{$self->{info}}));
    return (\@pages, $first, $last);
  }
  return \@pages;
}

sub getInfo {
  my ($self, %args) = @_;

  if (!defined($args{name})) {
    carp("A dashboard name must be specified with 'name => <name>'");
    return undef;
  }
  my $name = $args{name};
  $name .= "_dashboard" if ($name !~ /dashboard/);
  my $lcName = lc($name);
  $self->getAllDashboards() if !defined($self->{dashboards});

  my $realName = (grep(/^$lcName$/i, @{$self->{dashboards}}))[0];

  return $self->{info}{$realName} if $realName && ($self->{info}{$realName} && (!$args{force}));

  if (!defined($realName)) {
    carp("Can't find dashboard of name $args{name}") unless $args{noWarn};
    return undef;
  }

  my $subName = $args{subName};

  my $content = $self->{wiki}->getPage($realName);
  # print "Got content from $realName\n" if $content;
  

  my $te  = new HTML::TableExtract(headers => [qw(Milestone Plan Forecast Actual)] );
  $te->parse($content);

  if ($te->tables == 0) {
    $te  = new HTML::TableExtract(headers => [qw(Milestone Date Actual)] );
    $te->parse($content);
  }

  if ($te->tables == 0) {
    $te  = new HTML::TableExtract(headers => [qw(Milestone Date)] );
    $te->parse($content);
  }
  
  if ($te->tables == 0) {
    $te  = new HTML::TableExtract(headers => [qw(Milestone Plan Actual)] );
    $te->parse($content);
  }

  if ($te->tables == 0) {
    $te  = new HTML::TableExtract(headers => [qw(Milestone Plan)] );
    $te->parse($content);
  }


  if ($te->tables == 0) {
    carp("Failed to parse date information from dashboard: $realName") unless $args{noWarn};
    return undef;
  }

  my ($iterName) = ($realName =~ /\s*(.*?)_dashboard/i);
  
  my %iterInfo = (name => $iterName);
  foreach my $ts ($te->tables) {

    foreach my $row ($ts->rows) {
      my $pTime = $self->parseDateRow($row);
      next if !$pTime;
      print "$row->[0]: $pTime\n";

      my $milestone = $row->[0];
      
      if ($milestone =~ /^\s*(.*?)?\s*iter\w*\s+start/i) {
        if (!$subName || !$1 || $1 eq $subName) {
          $iterInfo{'iteration-start'} = $pTime;
        }
      }
      elsif ($milestone =~ /^\s*(.*?)?\s*qa\s+start/i) {
        print "$subName || !$1 || $1 eq $subName\n";
        if (!$subName || !$1 || $1 eq $subName) {
          $iterInfo{'qa-start'} = $pTime;
        }
      }
      elsif ($milestone =~ /^\s*(.*?)?\s*(iter\w*\s+)?complete|end/i) {
        if (!$subName || !$1 || $1 eq $subName) {
          $iterInfo{'iteration-complete'} = $pTime;
        }
      }

    }
  }

  print Dumper \%iterInfo;
  my $haveSomething = 0;
  foreach my $key (qw(iteration-start qa-start iteration-complete)) {
    if (defined($iterInfo{$key})) {
      $haveSomething = 1;
    }
  }

  if (!$haveSomething) {
    return undef;
  }
  

  # foreach my $key (qw(Start End StartActual EndActual QaStart QaStartActual)) {
  #   $iterInfo{"${key}Str"} =~ s/^\s*|\s*$//g if defined($iterInfo{"${key}Str"});
  # }


  # print Dumper \%iterInfo;

  # print "$iterName:\n";
  # print "  Start: $iterInfo{StartStr}\n";
  # print "  QA:    $iterInfo{QaStartStr}\n";
  # print "  End:   $iterInfo{EndStr}\n";

  $self->{info}{$realName} = \%iterInfo;
      
  return \%iterInfo;

}


sub parseDateRow {
  my ($self, $row) = @_;

  my @cells = @{$row};

  while (@cells) {
    my $cell = pop(@cells);
    next if !defined($cell);

    my @lines = split(/\n/, $cell);

    while (@lines) {
      my $line = pop(@lines);

      my $time = str2time($line);
      return $time*1000 if $time;

      if ($line =~ /\(\s*([^\)]+)\s*\)/) {
        $time = str2time($1);
        return $time*1000 if $time;
      }

    }

  }
  
  return undef;

}

sub getInfoV2 {
  my ($self, %args) = @_;

  if (!defined($args{name})) {
    carp("A dashboard name must be specified with 'name => <name>'");
    return undef;
  }

  my $name = $args{name};

  $name .= "_dashboard" if ($name !~ /dashboard/);

  my $lcName = lc($name);
  $self->getAllDashboards() if !defined($self->{dashboards});
  my $realName = (grep(/^$lcName$/i, @{$self->{dashboards}}))[0];

  return $self->{infoV2}{$realName} if $realName && ($self->{infoV2}{$realName} && 
                                                     (!$args{force}));

  if (!defined($realName)) {
    carp("Can't find dashboard of name $args{name}") unless $args{noWarn};
    return undef;
  }

  my $content = $self->{wiki}->getPage($realName);

  my $te  = new HTML::TableExtract(headers => [qw(Milestone Plan Forecast Actual)]);
  $te->parse($content);

  if ($te->tables == 0) {
    carp("Can't parse summary table at top of dashboard") unless $args{noWarn};
    return undef;
  }

  my ($iterName) = ($realName =~ /\s*(.*?)_dashboard/i);

  sub convertDates {
    my ($row) = @_;
    my @dates;
    my $best;
    for my $i (1..3) {
      if ($row->[$i]) {
        $dates[$i] = str2time($row->[$i]);
        $best = $dates[$i] if $dates[$i];
      }
    }
    return {
      plan     => $dates[1],
      forecast => $dates[2],
      actual   => $dates[3],
      best     => $best
    };
  }

  my %iterInfo = (name => $iterName);
  foreach my $ts ($te->tables) {
    foreach my $row ($ts->rows) {
      if ($row->[0] =~ /iter\w*\s+(complete|end)/i) {
        $iterInfo{end} = convertDates($row);
      }
      elsif ($row->[0] =~ /iter\w*\s+start/i) {
        $iterInfo{start} = convertDates($row);
      }
      elsif ($row->[0] =~ /qa\w*\s+start/i) {
        $iterInfo{qaStart} = convertDates($row);
      }
    }
  }
  return \%iterInfo;

}


sub getAllInfo {
  my ($self, $minIteration) = @_;

  $self->getAllDashboards($minIteration) if 
      !defined($self->{dashboards}) || $self->{minIteration} != $minIteration;

  foreach my $dash (@{$self->{dashboards}}) {
    $self->{info}{$dash} = $self->getInfoV2(name => $dash, noWarn => 1);
  }

}

sub getAllCurrentDashboards {
  my ($self, $fuzzInDays, $minIteration) = @_;

  $fuzzInDays ||= 0;

  $self->getAllInfo($minIteration);

  my $now = time();
  my %current;
  foreach my $dash (keys(%{$self->{info}})) {
    my $di = $self->{info}{$dash};
    my ($itNum) = ($dash =~ /[dD](\d+)/);
    if ($itNum && $itNum < 25) {
      next;
    }
    if (defined($di->{start}{best}) &&
        defined($di->{end}{best}) &&
        $di->{start}{best} < ($now + $fuzzInDays*24*3600) && 
        $di->{end}{best} > ($now - $fuzzInDays*24*3600)) {
      $current{$dash} = $di->{start}{best};
    }
  }
  
  my @curr = (sort {$current{$a} <=> $current{$b}} keys(%current));

  my $last = 0;
  my $first = 0xffffffff;
  map {$last = $self->{info}{$_}{end}{best} if $self->{info}{$_}{end}{best} > $last} @curr;
  map {$first = $self->{info}{$_}{start}{best} if $self->{info}{$_}{start}{best} < $first} @curr;

  $self->{currFirst} = $first;
  $self->{currLast}  = $last;
  $self->{currList}  = \@curr;

  return (\@curr, $first, $last) if wantarray;
  return \@curr;

}



1;

