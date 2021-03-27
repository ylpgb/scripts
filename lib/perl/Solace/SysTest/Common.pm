package Solace::SysTest::Common;

use strict;
use warnings;

use File::Path;

use Solace::SysTest::Log qw(Debug Info Warn Error);

BEGIN {
    my $host = `hostname -I | awk '{print \$1}'`;
    chomp $host;
    if ($host ne "192.168.3.133") {
        Error("Please run from sol-qa-33 at 192.168.3.133");
        exit 1;
    }
}

sub GetHome() {
    #REZA
    #return "/home/rataei/svndir/devenv/devtools/dhorton";
    my $home = $ENV{SYSTEST_HOME};
    if (!$home) {
        $home = $ENV{HOME} . "/.systest";
    }
    if ($home) {
        mkpath($home);
    }
    else {
        Error("No SYSTEST_HOME or HOME is set");
    }
    return $home
}

sub GetSystemTestDir() {
    my $cfgdir = Solace::SysTest::Common::GetHome() . "/system-test";
    mkpath($cfgdir);
    return $cfgdir;
}

sub GetCfgDir() {
    my $cfgdir = Solace::SysTest::Common::GetHome() . "/cfgs";
    mkpath($cfgdir);
    return $cfgdir;
}

sub GetLogDir($) {
    my ($type) = @_;
    #my $logdir = Solace::SysTest::Common::GetHome() . "/logs/$type";
    my $logdir = "/var/clients-log/$type";
    mkpath($logdir);
    return $logdir;
}


END {
}

1;
