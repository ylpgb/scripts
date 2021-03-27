package Solace::SysTest::ConfigFile;

use strict;
use warnings;
use Data::Dumper;
use Solace::SysTest::Log qw(Debug Info Warn Error);

BEGIN {
}

sub Init($$) {
    my ($type,$file_name) = @_;

    my $cfgdir = Solace::SysTest::Common::GetCfgDir();
    my $cfg = "$cfgdir/$file_name.cfg";

    my %info;

    if (!open(FH, $cfg)) {
	Warn("Unable to find config file $cfg");
	return \%info;
    }

    my $name;

    ## Read in config from file.  Syntax is as follows:
    ##
    ## type <name>
    ##   <property> <value>
    ##   <property> <value>
    ##   ...
    ## type <name>
    ##   <property> <value>
    ##   <property> <value>
    ##   ...
    ##
    ## Properties and their values are entirely arbitrary, and are
    ## returned in a hash.

    my $lineno = 0;
    my $pragma_loop_count = 0;
    my $start_char = 0;
    LINE: while (<FH>) {
        chomp;
        s/\s*$//g;
        $lineno++;
        last if (/^EOF$/);     ## EOF flag
        #print("\n$lineno\nline after EOF\n");
        next LINE if (/\s*^#/);     ## comment
        next LINE if (/^\s*$/);     ## blank        
        if (/^pragma/) {
            if (/loop\s(\d+)/) {
                $pragma_loop_count = $1;
                $start_char = tell(FH);
                next LINE;
            } else {
                next LINE;
            }
        }
        if (/end pragma/) {
            $pragma_loop_count--;
            if ($pragma_loop_count) {
                seek(FH,$start_char,0);
                next LINE;
            }
        }
        if (/^\s*$type\s+(.+)\s*$/) {   ## type <name>
        $name = $1;
            die "AHHH $_" if ($name =~ /^\s*$/);
            if ($pragma_loop_count) {
                my $i = $pragma_loop_count;
                if ($name =~ /<% (.*) %>/) {
                    my $s = eval $1;
                    $name =~ s/<%.*%>/$s/g;
                }
            }
            $info{$name}{name} = $name;
        }
        elsif (/\s*(\S+)\s+(\S.*$)/) { ## <propeprty> <value>
            my $value = $2;
            if ($pragma_loop_count) {
                my $i = $pragma_loop_count;
                my @in_tokens = split /<%/,$value;
                my $out = "";
                foreach my $token (@in_tokens) {
                    if ($token =~ /(.*) %>/) {
                        my $s = eval $1;
                        $token =~ s/.*%>/$s/;
                        $out .= $token;
                    } else {
                        $out .= $token
                    }
                }
                $value = $out;
            }
	    $info{$name}{$1} = $value;
        } else {
            die ("failed to parse $lineno: $_\n");
        }
    }
    close(FH);

    return \%info;
}

sub Display($$) {
    my ($type, $info) = @_;
    print("\n");
    print("$type " . $info->{name} . "\n");

    foreach my $key (sort(keys(%{$info}))) {
	if ($key ne "name") {
	    printf("  %-27s : %s\n", $key, $info->{$key});
	}
    }
}


END {
}

1;
