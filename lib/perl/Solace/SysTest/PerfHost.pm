package Solace::SysTest::PerfHost;

use strict;
use warnings;

use Solace::SysTest::Log qw(Debug Info Warn Error);
use Solace::SysTest::ConfigFile;

BEGIN {
}

sub Init($) {
    my $cloud = shift;
    my $perfs = "";
    if ($cloud) {
        $perfs = Solace::SysTest::ConfigFile::Init("perfhost","perfhost");
    } else {
        $perfs = Solace::SysTest::ConfigFile::Init("perfhost","perfhost");
    }

    ## Select defaults for anything not specified.
    foreach my $key (keys(%{$perfs})) {
    }

    return $perfs;
}

sub Display($) {
    my ($perf) = @_;
    Solace::SysTest::ConfigFile::Display("PerfHost", $perf);
}


END {
}

1;
