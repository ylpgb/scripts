package Solace::SysTest::Top;

use strict;
use warnings;

use Solace::SysTest::Log qw(Debug Info Warn Error);

BEGIN {
}

## Get 'top' data for the given pids on the given host.  Returns a
## hash whose keys are the process names for the given pids, with
## value being another hash whos keys are the labels from a normal top
## output.
##
sub ForPid($@) {
    my ($host, @pids) = @_;

    my %out;

    my $user = ($host =~ m/^dev/) ? "" : "root\@";
    my $cmd = "top -b -n1 -p " . join(",", @pids);
    my @top = `ssh $user$host $cmd`;

    ## skip down in output past the first blank line.
    while (shift(@top) !~ m/^$/) {}
    foreach (@top) { chomp; }

    my @hdrs = split(/ +/, shift(@top));
    if ($hdrs[0] eq "") {shift(@hdrs);}

    while (@top) {
	my @vals = split(/ +/, shift(@top));
	if (@vals) {
	    if ($vals[0] eq "") {shift(@vals);}
	    my %hash;
	    foreach my $hdr (@hdrs) {
		$hash{$hdr} = shift(@vals);
	    }
	    $out{$hash{COMMAND}} = \%hash;
	}
    }
    return \%out;
}

## As ForPid, but for all the children of the given parent pid.
##
sub ForPPid($$) {
    my ($host, $ppid) = @_;
    my $cmd = "ps --ppid $ppid | grep -v PID | awk '{print \$1}'";
    my $user = ($host =~ m/^dev/) ? "" : "root\@";
    my @pids = `ssh $user$host $cmd`;
    foreach (@pids) { chomp; }
    return ForPid($host, @pids);
}

END {
}

1;
