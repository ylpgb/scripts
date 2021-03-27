package Solace::SysTest::Log;

use strict;
use warnings;

BEGIN {
    use Exporter();
    our (@ISA, @EXPORT);
    @ISA = qw(Exporter);
    @EXPORT = qw(Debug Info Warn Error Event DateStr);
}

our $debug = 0;
our $info = 0;
our $warn = 1;
our $error = 1;

sub Debug($) {
    if (!$debug) {return;}
    print("DEBUG: " . $_[0] . "\n");
}

sub Info($) {
    if (!$info) {return;}
    print("INFO: " . $_[0] . "\n");
}

sub Warn($) {
    if (!$warn) {return;}
    print("WARN: " . $_[0] . "\n");
}

sub Error($) {
    if (!$error) {return;}
    print("ERROR: " . $_[0] . "\n");
}

sub Event($$) {
    my ($event_log_file,$message) = @_;

    my $event_log_handle;
    if ($event_log_file ne "") {
        open($event_log_handle,">>",$event_log_file);
    } else {
        open($event_log_handle,">>","/dev/null");
    }
 
    my $outstr = '"'.join('","',DateStr(),$message) .'"'."\n";
    print $event_log_handle $outstr;
    close $event_log_handle;
}

sub DateStr() {
    my ($sec, $min, $hr, $day, $mon, $y) = (localtime(time))[0..5];
    return sprintf "%d-%02d-%02dT%02d:%02d:%02d", $y+1900,$mon+1,$day,$hr,$min,$sec;    
}
END {
}

1;
