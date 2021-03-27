package Solace::SysTest::Client;

use strict;
use warnings;
use threads;

use XML::XPath;
use Logfile::Rotate;

use Solace::SysTest::Log qw(Debug Info Warn Error);
use Solace::SysTest::ConfigFile;
use Solace::SysTest::Table;

use Data::Dumper;

BEGIN {
}

sub Init($) {
    my $cloud = shift;
    my $clients = "";
    if ($cloud) {
        $clients = Solace::SysTest::ConfigFile::Init("client","client-cloud");
    } else {
        $clients = Solace::SysTest::ConfigFile::Init("client","client");
    }
    ## Select defaults for anything not specified.
    foreach my $key (keys(%{$clients})) {
    	if (!exists($clients->{$key}{vr})) {
    	    $clients->{$key}{vr} = "primary";
    	}
    	if (!exists($clients->{$key}{tool})) {
    	    $clients->{$key}{vr} = "sdkperf_c";
    	}
    	if (!exists($clients->{$key}{"log-rotate"})) {
    	    $clients->{$key}{"log-rotate"} = 10;
    	}
    	## Default tolerance to expected rates to +/- 10%.
    	if (!exists($clients->{$key}{"expected-ingress-tolerance"})) {
    	    $clients->{$key}{"expected-ingress-tolerance"} = 10;
    	}
    	if (!exists($clients->{$key}{"expected-egress-tolerance"})) {
    	    $clients->{$key}{"expected-egress-tolerance"} = 10;
    	}
    	if (!exists($clients->{$key}{"audit"})) {
    	    $clients->{$key}{"audit"} = "yes";
    	}        
        if (!exists($clients->{$key}{"ok-to-have-missed-msgs"})) {
            $clients->{$key}{"ok-to-have-missed-msgs"} = "no";
        }
    }

    return $clients;
}

sub Display($) {
    my ($client) = @_;
    Solace::SysTest::ConfigFile::Display("Client", $client);
}

sub _Stop1($$$$$) {
    my ($perf, $label, $signal, $check,$name) = @_;
    my $user = ($perf =~ m/^dev/) ? "" : "root\@";
    my $tries = 30;
    my $pgrep = "ssh -n $user$perf pgrep -f $label";

    my $parents = `$pgrep`;
    foreach my $parent (split("\n",$parents)) {
        chomp($parent);
        if ($parent) {            
            print "Found parent: $parent\n";
            if ($check) {
                print "checking\n";
                sleep 0.5;
                my $i = 0;
                while ((`$pgrep` =~ /$parent/) && ($i < $tries)) {
                    $i++;
                    print "$i ";
                    sleep 1;
                }
                print "\n";
                if ($i >= $tries) {
                    print "WARNING: pid $parent, client $label isn't dead yet!\n";
                }
            }
            print "Killing $parent\n";
            my $logdir = Solace::SysTest::Common::GetLogDir("client");
            my $logfile = "$logdir/$name.log";
            my $host = `hostname -I | awk '{print \$1}'`;
            chomp $host;
            system("echo '\n\nsystest (from $host) is killing the process (for client $name)\n\n' >> $logfile;usleep 100000");
            system("ssh -n $user$perf 'kill -$signal -- -$parent'");
        }
    }
}

sub Start1($$$) {
    my ($client, $rtrs, $perfs, $check) = @_;

    my $name = $client->{name};
    chomp $name;

    print("Starting client '$name'\n");

    my $cmd = "$client->{tool}";

    #We often have a problem with softlinks getting changed to invalid
    #pointers during the test.  This flag directs the script to
    #dereference those so they'll be static for the duration of the
    #test.
    if (exists($client->{"dereference"})) {
        my $deref = "$client->{dereference}";
        if ($deref =~ /[Yy]/) {
            $cmd = `readlink -f $cmd`;
            chomp $cmd;
        }
    }

    my $wrapper = $client->{wrapper};
    if ($wrapper) {
    ## Wrap cmd in the given wrapper script.  Use -- to prevent
    ## options from cmd being interpreted by the wrapper.
        $cmd = "$wrapper " . $cmd;
    }

    my $rtr = $rtrs->{$client->{router}};

    my $ip = $rtr->{"host-msgbb-$client->{vr}"};
    if (!$ip) {
        Error("No " . $client->{vr} . " ip-addr for " . $client->{router} . ", got $ip");
        return;
    }
    
    my $port = "";
    if ($client->{"ssl-transport"}) {
        $port = $rtr->{"port-ssl"};

    } elsif ($client->{"web-transport"}) {
        $port = $rtr->{"port-web"};

    } elsif ($client->{args} =~ /-z=/) {
        $port = $rtr->{"port-smfc"};

    } elsif ($client->{"ssl-web-transport"}) {
        $port = $rtr->{"port-ssl-web"};

    } else {
        $port = $rtr->{"port-smf"}; 
    }

    my $protocol = "";
    if ($client->{"web-transport"}) {
        $protocol = "http://";
    } elsif ($client->{"ssl-transport"}) {
        $protocol = "tcps://";
    } elsif ($client->{"ssl-web-transport"}) {
        $protocol = "https://";
    }

    my $eplDefaults = 0;
    if (exists($client->{"default-args"}) && 
        (($client->{"default-args"} eq "no") || 
         ($client->{"default-args"} eq "0"))) {
        $cmd .= " ".$client->{args};
    } else {
        my $cip = "";
        foreach my $hip (split(',', $ip)) {
            $cip .= "$protocol$hip:$port,";
        }
        chop($cip);
        $cmd .= " -cip=$cip -cn=${name}_ -crc -lat -rc=999 " . $client->{args};
        if (exists($client->{"latency"}) &&
            (($client->{"latency"} eq "no") || 
             ($client->{"latency"} eq "0"))) {
            $cmd =~ s/-lat//g;
        }
        if (exists($client->{"crc"}) &&
            (($client->{"crc"} eq "no") || 
             ($client->{"crc"} eq "0"))) {
            $cmd =~ s/-crc//g;
        }
    }
    if (($client->{"tool"} =~ m/sdkperf_c|rtrperf_tr|sdkperf_jni|rtrperf_jni/) &&
        !(exists($client->{"epl"}) && ($client->{"epl"} =~ m/SESSION_CONNECT_RETRIES,/))) {
        $cmd .= " -epl=SESSION_CONNECT_RETRIES,-1";
        $eplDefaults = 1;
    } elsif (($client->{"tool"} =~ m/sdkperf_java|rtrperf_java/) &&
             !(exists($client->{"epl"}) && ($client->{"epl"} =~ m/jcsmp.CLIENT_CHANNEL_PROPERTIES.connectRetries,/))) {
        $cmd .= " -epl=jcsmp.CLIENT_CHANNEL_PROPERTIES.connectRetries,-1";
        $eplDefaults = 1;
    }

    if (exists($client->{"epl"})) {
        if ($eplDefaults == 1) {
            $cmd .=  "," . $client->{epl};
        } else {
            $cmd .= " -epl=" . $client->{epl};
        }
    }

    my $wrapper_end = $client->{"wrapper-end"};
    if ($wrapper_end) {
        $cmd .= " $wrapper_end";
    }

    my $perf = $perfs->{$client->{perfhost}}{dnsname};

    ## A label which makes it easy to find the remote process to kill.
    my $label = "SYSTEST_CLIENT_$name";
    my $signal = "SIGINT";
    if (exists($client->{"kill-signal"})) {
        $signal = $client->{"kill-signal"};
    }

    _Stop1($perf, $label, $signal, $check, $name);

    Debug("Starting client $name: $cmd");
    print("Starting client $name: $cmd\n\n");

    my $logdir = Solace::SysTest::Common::GetLogDir("client");
    my $logfile = "$logdir/$name.log";

    ## Rotate last client log.
    my $count = $client->{"log-rotate"};
    if ($count > 0 && -e $logfile) {
	my $log = new Logfile::Rotate(File => $logfile, Count => $count);
	$log->rotate();
	undef $log;
    }
    
    my $user = ($perf =~ m/^dev/) ? "" : "root\@";

    system("echo 'Command to use:\n\n$cmd\n\n' > $logfile");
    system("ssh -n $user$perf 'echo $label && $cmd' &>> $logfile &");
    if (exists($client->{"sleep"})) {
        sleep $client->{"sleep"}
    }
}

sub Start($$$$) {
    my ($rtrs, $perfs, $clients, $args) = @_;

    ## Use $args as our keys if provided.  That is, only start a given
    ## subset of our clients.
    # Reza: what is this doing? wrong code? why index 0? Assuming $cmds is always empty (as the last command has the handler). Why the cmds is passed in then?
    my $output_format = ${$args}[0];
    splice(@{$args},1,1);

    my @keys = keys(%{$clients});

    my $thrds = [];
    foreach my $key (sort(@keys)) {
	if (exists($clients->{$key})) {
	    Start1($clients->{$key}, $rtrs, $perfs);
	}
	else {
	    Warn("Client '$key' does not exist");
	}
    }
}

sub Stop1($$$$) {
    my ($client, $rtrs, $perfs, $check) = @_;
    my $name = $client->{name};

    print("Stopping client '$name'\n");

    my $perf = $perfs->{$client->{perfhost}}{dnsname};
    $perf or die ("couldn't find dnsname for '$client->{name}': '$client->{perfhost}'");
    ## A label which makes it easy to find the remote process to kill.
    my $label = "SYSTEST_CLIENT_$name";
    my $signal = "SIGINT";
    if (exists($client->{"kill-signal"})) {
        $signal = $client->{"kill-signal"};
    }

    return _Stop1($perf, $label, $signal, $check,$name);
}

sub ProcessLog($$$) {
    my ($client, $errTbl, $cacheErrTbl) = @_;
    my $name = $client->{name};
    my $logdir = Solace::SysTest::Common::GetLogDir("client");
    my $logfile = "$logdir/$name.log";

    #open(FH, "$logfile") or die("Cannot open logfile '$logfile'");
    if(-e $logfile) {
        open(FH, $logfile);
    } else {
        Error("Cannot open logfile '$logfile'")
    }

    #SDK Errors aren't in the table.  They're alarmed separately.  If
    #you've got an SDK ERROR log, you should go look and see what
    #happened to each client.
    my $sdkErrs = 0;
    my ($tx, $rx, $ooo, $miss, $dup, $redel, $redelDup, $repubDup, $crc) = (0) x $errTbl->n_cols();

    my ($cache_requests_sent,
        $cache_requests_received,
        $cache_requests_completed_ok,
        $cache_requests_incomp_no_data,
        $cache_requests_incomp_suspect,
        $cache_requests_incomp_timeout,
        $cache_requests_errored,
        $cache_requests_live_data_rx,
        $cache_requests_data_msgs_recv,
        $cache_requests_data_msgs_suspect,
        $cache_requests_resp_discards) = (0) x $cacheErrTbl->n_cols();
    
    ## Accumulate all numbers, as they may be encountered multiple
    ## times in a single logfile.
    ##
    while (<FH>) {
        if (/SDK ERROR/) {
            $sdkErrs += 1;
        }
	if (/Total Messages transmitted * = (\d+)/) {
	    $tx += $1;
	}
	elsif (/Total Message\w* received across all \w+ = (\d+)/) {
	    $rx += $1;
	}
	elsif (/Message Order Check Summary:/) {
            ORDER: while (<FH>) {
                if (/Total Msgs Order Checked *: (\d+)/) {
		    ## Nothing to do.
                }
                elsif (/Total Out of Order Msgs *: (\d+)/) {
                    $ooo += $1;
		    if ($1) {
			print("*** Client $name has out-of-order messages\n");
		    }
                }
                elsif (/Total Missing Msgs *: (\d+)/) {
                    $miss += $1;
		    if ($1) {
                if ($client->{"ok-to-have-missed-msgs"} ne "yes") {
                    print("*** Client $name has missing messages\n");
                }
		    }
                }
                elsif (/Total Duplicate Msgs *: (\d+)/) {
                    $dup += $1;
		    if ($1) {
			print("*** Client $name has duplicated messages\n");
		    }
                }
                elsif (/Total Redelivered Msgs *: (\d+)/) {
                    $redel += $1;
		    # if ($1) {
		    #     print("*** Client $name has redelivered messages\n");
		    # }
                }
                elsif (/Total Redelivered Duplicate Msgs *: (\d+)/) {
                    $redelDup += $1;
		    # if ($1) {
		    #     print("*** Client $name has redelivered duplicate messages\n");
		    # }
                }
                elsif (/Total Republished Duplicate Msgs *: (\d+)/) {
                    $repubDup += $1;
                }
                elsif (/failed to execute/) {
                    print("*** Client $name failed to execute!!! ***");
                }
                elsif (/^$/) {
                    last ORDER;
                }
                else {
                    Warn("Unknown order check stat: $_");
                }
            }
	}
	elsif (/Message Integrity Checking:/) {
            CRC: while (<FH>) {
                if (/Total Messages with ERRORS *= (\d+)/) {
		    $crc += $1;
		    if ($1) {
			print("*** Client $name has CRC errors\n");
		    }
                }
                elsif (/^$/) {
                    last CRC;
                }
	    }
	}
	elsif (/Cache Stats:/) {
	  CRC: while (<FH>) {
	      if (/Num Requests Sent *= (\d+)/) {
                  $cache_requests_sent += $1;
              }
              elsif (/Num Responses Recv *= (\d+)/) {
                  $cache_requests_received += $1;
              }
              elsif (/Num Requests Completed OK *= (\d+)/) {
                  $cache_requests_completed_ok += $1;
              }
              elsif (/Num Requests Incomp no data *= (\d+)/) {
                  $cache_requests_incomp_no_data += $1;
              }
              elsif (/Num Requests Incomp suspect *= (\d+)/) {
                  $cache_requests_incomp_suspect += $1;
              }
              elsif (/Num Requests Incomp timeout *= (\d+)/) {
                  $cache_requests_incomp_timeout += $1;
              }
              elsif (/Num Requests Errored *= (\d+)/) {
                  $cache_requests_errored += $1;
              }
              elsif (/Num Live Data Msgs Recv *= (\d+)/) {
                  $cache_requests_live_data_rx += $1;
              }
              elsif (/Num Cached Data Msgs Recv *= (\d+)/) {
                  $cache_requests_data_msgs_recv += $1;
              }
              elsif (/Num Cached Data Msgs Suspect *= (\d+)/) {
                  $cache_requests_data_msgs_suspect += $1;
              }
              elsif (/Num Resp Discarded *= (\d+)/) {
                  $cache_requests_resp_discards += $1;
              }
              elsif (/^$/) {
                  last CRC;
              }
          }
        }        
    }
    if ($cache_requests_incomp_no_data ||
        $cache_requests_incomp_timeout ||
        $cache_requests_incomp_suspect) {
        my $total_incomplete = $cache_requests_incomp_no_data +
                               $cache_requests_incomp_timeout +
                               $cache_requests_incomp_suspect;
        print("*** Client $name has $total_incomplete incomplete cache requests\n");
    }

    if ($cache_requests_errored) {
        print("*** Client $name has $cache_requests_errored errored cache requests\n");
    }

    if ($sdkErrs) {
        my $phostName = $client->{perfhost};
        my $rtrName   = $client->{router};
        print ("*** Client $name, r:$rtrName, p:$phostName has $sdkErrs sdk error logs\n");
    }
    
    if ($cache_requests_sent != $cache_requests_received) {
        print("*** Client $name has missing cache requests.  sent: $cache_requests_sent received: $cache_requests_received\n");
    }
    
    close(FH);

    $errTbl->load([$name, $tx, $rx, $ooo, $miss, $dup, 
		   $redel, $redelDup, $repubDup, $crc]);

    if ($cache_requests_sent) {
        $cacheErrTbl->load([$name,
                            $cache_requests_sent,
                            $cache_requests_received,
                            $cache_requests_completed_ok,
                            $cache_requests_incomp_no_data,
                            $cache_requests_incomp_suspect,
                            $cache_requests_incomp_timeout,
                            $cache_requests_errored,
                            $cache_requests_live_data_rx,
                            $cache_requests_data_msgs_recv,
                            $cache_requests_data_msgs_suspect,
                            $cache_requests_resp_discards]);
    }
        

}

sub Stop($$$$) {
    my ($rtrs, $perfs, $clients, $args) = @_;

    my	@keys = keys(%{$clients});

    my $errTbl = Solace::SysTest::Table::Get(["Name",
					      "TotalTx",
					      "TotalRx",
					      "OoO",
					      "Missing",
					      "Dup",
					      "Redel",
					      "RedelDup",
                          "RepubDup",
					      "CRC"]);

    my $cacheErrTbl = Solace::SysTest::Table::Get(["Name",
                                                   "TotalTx",
                                                   "TotalRx",
                                                   "OK",
                                                   "No Data",
                                                   "Suspect",
                                                   "Timeout",
                                                   "Errored",
                                                   "Live Msgs Rx",
                                                   "Cached Msgs Rx",
                                                   "Msgs Rx Suspect",
                                                   "Response Discarded"]);
    


    print "Pass 1\n";
    foreach my $key (sort(@keys)) {
	if (exists($clients->{$key})) {
            my $nocheck = 0;
	    Stop1($clients->{$key}, $rtrs, $perfs,$nocheck);
	}
	else {
	    Warn("Client '$key' does not exist");
	}
    }
    print "Pass 2\n";
    foreach my $key (sort(@keys)) {
	if (exists($clients->{$key})) {
            my $check = 1;
	    Stop1($clients->{$key}, $rtrs, $perfs,$check);
	}
	else {
	    Warn("Client '$key' does not exist");
	}
    }

    foreach my $key (sort(@keys)) {
	if (exists($clients->{$key})) {
            ProcessLog($clients->{$key}, $errTbl,$cacheErrTbl);
	}
    }

    #The java clients mostly live on c17, and just. don't. die.  I
    #really need to find a more elegant way to do this
    print `ssh root\@c17 pkill java`;

    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Message Error Summary", $errTbl);
    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Cache Error Summary", $cacheErrTbl);
}

sub CheckLogs($$$$) {
    # Really only here to test the ProcessLog subroutine.
    my ($rtrs, $perfs, $clients, $args) = @_;

    my	@keys = keys(%{$clients});

    my $errTbl = Solace::SysTest::Table::Get(["Name",
					      "TotalTx",
					      "TotalRx",
					      "OoO",
					      "Missing",
					      "Dup",
					      "Redel",
					      "RedelDup",
                          "RepubDup",
					      "CRC"]);

    my $cacheErrTbl = Solace::SysTest::Table::Get(["Name",
                                                   "TotalTx",
                                                   "TotalRx",
                                                   "OK",
                                                   "No Data",
                                                   "Suspect",
                                                   "Timeout",
                                                   "Errored",
                                                   "Live Msgs Rx",
                                                   "Cached Msgs Rx",
                                                   "Msgs Rx Suspect",
                                                   "Response Discarded"]);

    foreach my $key (sort(@keys)) {
	if (exists($clients->{$key})) {
            ProcessLog($clients->{$key}, $errTbl,$cacheErrTbl);
	}
    }

    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Message Error Summary", $errTbl);
    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Cache Error Summary", $cacheErrTbl);

}

END {
}

1;
 
