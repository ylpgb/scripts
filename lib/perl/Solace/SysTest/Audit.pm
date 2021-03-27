package Solace::SysTest::Audit;

use strict;
use warnings;

use XML::XPath;

use Solace::SysTest::Log qw(Debug Info Warn Error);
use Solace::SysTest::Table;
use Solace::SysTest::Top;

BEGIN {
}

sub Client1($$$$$) {
    my ($client, $rtrs, $perfs, $tbl, $results) = @_;
    
    baseClient($client, 
               $rtrs, 
               $perfs, 
               $tbl, 
               $results, 
               "current-ingress-rate-per-second", 
               "current-egress-rate-per-second")
}

sub avgClient($$$$$) {
    my ($client, $rtrs, $perfs, $tbl, $results) = @_;
    
    baseClient($client, 
               $rtrs, 
               $perfs, 
               $tbl, 
               $results, 
               "average-ingress-rate-per-minute", 
               "average-egress-rate-per-minute")
}


sub baseClient($$$$$$$) {
    my ($client, $rtrs, $perfs, $tbl, $results, $ingressStat, $egressStat) = @_;
    
    my $name = $client->{name};
    my $numClients = 1;
    if ($client->{args} =~ /cc=(\d+)/) {
        $numClients = $1;
    }
    my @clientsFound;

    my $rtr = $rtrs->{$client->{router}};
    my $mate = $rtrs->{$rtr->{mate}};

    my $inExpect = "n/a";
    my $egExpect = "n/a";

    my ($inExpectLo, $inExpectHi);
    my ($egExpectLo, $egExpectHi);
    my $inTolerance = $client->{"expected-ingress-tolerance"};
    my $egTolerance = $client->{"expected-egress-tolerance"};

    if (defined($client->{"expected-ingress-rate"})) {
        $inExpect = $client->{"expected-ingress-rate"};
        #Make sure that the low end is always above zero
        if ($inTolerance > 100) {
            $inExpectLo = 1;
        } else {
            $inExpectLo = $inExpect * ((100-$inTolerance)/100);
        }
        $inExpectHi = $inExpect * ((100+$inTolerance)/100);
    }
    if (defined($client->{"expected-egress-rate"})) {
        $egExpect = $client->{"expected-egress-rate"};
        #Make sure that the low end is always above zero
        if ($egTolerance > 100) {
            $egExpectLo = 1;
        } else {
            $egExpectLo = $egExpect * ((100-$egTolerance)/100);
        }
        $egExpectHi = $egExpect * ((100+$egTolerance)/100);
    }
    
    ## Check both host router and its mate for the client, which could
    ## be attached to either depending on redundancy.
  LOOP:
    for my $r ($rtr, $mate) {
        if (!$r) {
            next LOOP;
        }
        my $client_name_on_router = "*${name}*";
        if (defined($client->{rdp})) {
            my $rdp_name = $client->{rdp};
            $client_name_on_router = "#rdp/${rdp_name}";
            if (defined($mate) && $r eq $mate) {
                # TODO: what if we want to test failover?
                next LOOP;
            }
        }
        if (defined($mate) && $r eq $mate && $name =~ /mqtt/) {
            # TODO: what if we want to test failover?
            next LOOP;
        }
        my ($status, $xml) = Solace::SysTest::Router::SendSemp(
            $r, "<show><client><name>${client_name_on_router}</name><stats/></client></show>");

        if (!($status =~ /200/)) {
            #TODO: Put these logs into some kind of event table
            Warn("Didn't get good data for client $name, router ${$r}{'hostname'}, perfhost $client->{perfhost}.  Status was $status and received xml was:\n$xml");
        } else {
            my $maxIn  = 0;
            my $minIn  = 100000000;
            my $maxEg = 0;
            my $minEg = 100000000;
            my $clientFound = 0;

            my $xp = XML::XPath->new(xml => $xml);

            my @cns = $xp->findnodes("//show/client/*/client");

            foreach my $cn (@cns) {
                $clientFound = 1;
                my $n = $xp->findvalue("name", $cn);
                my $stats = $xp->find("stats", $cn)->get_node(1);

                my $in = $xp->findvalue($ingressStat,
                            $stats)->value();
                my $eg = $xp->findvalue($egressStat,
                            $stats)->value();

                my $number = substr($n,(length($n) - 4),length($n));
                if (defined($client->{rdp})) {
                    $number = 1;
                }

                $clientsFound[$number] = 1;
                $maxIn = $in if ($in > $maxIn);
                $minIn = $in if ($in < $minIn);
                $maxEg = $eg if ($eg > $maxEg);
                $minEg = $eg if ($eg < $minEg);

                if ($inExpect ne "n/a" && 
                    ($in < $inExpectLo || $in > $inExpectHi)) {
                    push (@{$results},"*** Client $name no. $number on ${$r}{'hostname'} has ingress rate: $in versus $inExpect");
                }
                if ($egExpect ne "n/a" && 
                    ($eg < $egExpectLo || $eg > $egExpectHi)) {
                    push (@{$results},"*** Client $name no. $number on ${$r}{'hostname'} has egress rate: $eg versus $egExpect");
                }
            }
            my ($inMid, $inSpread) = (0,0);
            if ($inExpect ne "n/a") {
                ($inMid, $inSpread) = prepSpreadString($maxIn, $minIn)
            }

            my ($egMid, $egSpread) = (0,0);
            if ($egExpect ne "n/a") {
                ($egMid, $egSpread) = prepSpreadString($maxEg, $minEg);
            }
            if ($clientFound) {
                $tbl->load([$name, $r->{name}, $client->{perfhost},$inMid, $inSpread, $inExpect, $egMid, $egSpread, $egExpect,""]);
            } 

        }
    }
    
    for (my $i = 1; $i <= $numClients;$i++) {
        if (!$clientsFound[$i]) {
            #Check to see if it should be churning
            my $churning = "";
            if (defined($client->{wrapper})) {
                if ($client->{wrapper} =~ /churn/) {
                    $churning = "Churning ";
                }
            }
            my $phost = $client->{perfhost};
            my $rtr = $client->{router};
            push (@{$results},
                  "*** ${churning}Client $name #$i wasn't found on router $rtr.  Runs on phost $phost");
        }
    }
    
}


#Audits a queue for how many messages it has
sub QueuedMessages($$$$$) {

    my ($client, $rtrs, $perfs, $tbl, $results) = @_;

    my $name = $client->{name};
    my $queue = $client->{"audit-queue"};
    
    my $rtr = $rtrs->{$client->{router}};
    my $mate = $rtrs->{$rtr->{mate}};

    ## Check both host router and its mate for the client, which could
    ## be attached to either depending on redundancy.
  LOOP:
    for my $r ($rtr, $mate) {
    if (!$r) {
        next LOOP;
    }
    my ($status, $xml) = Solace::SysTest::Router::SendSemp(
        $r, "<show><queue><name>$queue</name></queue></show>");
    if ($status =~ /200/) {
            if (($xml =~ "Message-Spool Active data is Not Available") || 
                ($xml =~ "<type>Backup</type>")) {
                next LOOP;
            }

            my @expectations = split(",",$client->{"expected-num-messages"});
        my $xp = XML::XPath->new(xml => $xml);
        my @nodes = $xp->findnodes("//show/queue/queues/queue");            
            #Pad expectations
            while ($#nodes > $#expectations) {
                push(@expectations,$expectations[($#expectations-1)]);
            }
            foreach my $node (@nodes) {
                my $num_messages = $xp->findvalue("info/num-messages-spooled",$node);
                my $qname        = $xp->findvalue("name",$node);
                my $expected = pop(@expectations);

                if ($num_messages ne $expected) {
                    push (@{$results},"*** Client $name-$qname on ${$r}{'hostname'} has messages: $num_messages versus $expected");
                }
                $tbl->load(["$name-$qname", $r->{name}, $client->{perfhost},"n/a", "n/a", "n/a", "n/a", "n/a", "n/a",$num_messages]);
            }
            
    } else {
            push (@{$results},"*** Client $name looking for $queue on router ${$r}{'hostname'} hit a SEMP error $status");
        }
    }

}



sub prepSpreadString ($$) {
    my ($max, $min) = @_;
    my $mid = sprintf("%d",($max + $min)/2);
    my $spread = sprintf("%d",($max - $mid));
    return ($mid,$spread);
}

sub Client($$$$$) {
    my ($rtrs, $perfs, $clients, $args, $output_format) = @_;

    my @keys = sort(keys(%{$clients}));

    my %auditSchema = (
        "default" => \&Client1,
        "lvq-34334" => \&QueuedMessages,
        "average-rates" => \&avgClient
    );

    my $tbl = Solace::SysTest::Table::Get(["Name",
                       "Router", 
                                           "Perfhost",
                       "Ingress Rate\nMid ",
                                           "+/-",
                       "Ingress Rate\n(expect)",
                       "Egress Rate\nMid",
                       "+/-",
                       "Egress Rate\n(expect)",
                                           "Misc"]);

    my $results = [];
    foreach my $key (@keys) {
        if (exists($clients->{$key})) {
            if ($clients->{$key}{audit} eq "yes") {
                my $auditFunction = exists($clients->{$key}{"audit-function"}) ? $clients->{$key}{"audit-function"} : "default";
                &{$auditSchema{$auditFunction}}($clients->{$key}, $rtrs, $perfs, $tbl, $results);
            }
        }
        else {
            Warn("Client '$key' does not exist");
        }
    }

    if ($output_format eq "text") {
        print join("\n",@{$results});
        print("\n");
        Solace::SysTest::Table::DisplayWithTotal("Client Message Rates", $tbl);
        print("\n");
    } elsif ($output_format eq "csv") {
        my $sep = Solace::SysTest::Table::SEP;
    my @rows = $tbl->body(0, $tbl->body_height());
    my $numRows = $#rows;
    $tbl->clear();
    foreach my $row (@rows) {
        my @data = split(/\s+\|\s+/,$row);
        my $key = $data[0];
        my $feature = $clients->{$key}{"feature"};
        $data[4] = $feature;
        $tbl->load(\@data);
    }
        my $csvtbl = $tbl->select(0,\$sep,4,\$sep,1,\$sep,2,\$sep,3,\$sep,6);
        Solace::SysTest::Table::DisplayAsCsv($csvtbl);
    } elsif (($#{$results} > 0) && ($output_format eq "json")) {
        my ($sec, $min, $hr, $day, $mon, $y) = (localtime(time))[0..5];
        printf "%d-%02d-%02dT%02d:%02d:%02d", $y+1900,$mon+1,$day,$hr,$min,$sec;    
        my %out;
        foreach my $r (@{$results}) {
            $r =~ m/Client (\S+).*on (\S+) has [^:]+: (\S+) versus (\S+)/;
            my $x = $1;
            #Discard the client number. We don't need all 50 in the database, one will do
            #If it turns out to be a problem we can include a client count number later
            $r =~ s/no. (\S+) //;   
            $out{$x} = $r;
        }
        foreach (keys %out) {
            print ", $out{$_}";
        }
        print "\n";
    }
}

## Display stats for a set of discard nodes which are children
## to the given node.
sub DiscardTable($$$$$) {
    my ($xp, $node, $tbl, $name, $type) = @_;
    ## Total is first node, e.g. position()=1.
    my $total = $xp->findvalue("*[position()=1]", $node);
    my @stats = $xp->findnodes("*[position()>1]", $node);

    if ($total ne 0) {
    print("*** Router $name has $type discards\n");
    }

    ## For handling the defered creation of the table.
    my @hdrs = ("Name", "Total");
    my @vals = ($name, $total);

    foreach my $stat (@stats) {

    if (!defined($tbl)) {
        ## Make up an abbreviated label for this stat from
        ## its XML tag.  Take the first character of each
        ## part of the tag separated by '-'.
        my $label = $xp->findnodes_as_string(".", $stat);
        $label =~ s/^<([A-Za-z-]+)>.*$/$1/; ## get open tag text
        $label .= "-";  ## so that next sub work for last piece
        $label =~ s/(.).*?-/$1/g; ## take only first letter
        $label = uc($label);
        push(@hdrs, $label);
    }
    push(@vals, $xp->findvalue(".", $stat));
    }

    if (!defined($tbl)) {
    $tbl = Solace::SysTest::Table::Get(\@hdrs);
    }
    $tbl->load(\@vals);
    return $tbl;
}

sub Router1($$$$$) {
    my ($rtr, $idTbl, $edTbl, $cpuTbl, $redTbl) = @_;

    my $name = $rtr->{name};

    my ($status, $xml) = Solace::SysTest::Router::SendSemp(
    $rtr, "<show><stats><client/></stats></show>");
    if ($status =~ /200/) {
    my $xp = XML::XPath->new(xml => $xml);
    my $n = $xp->find("//show/stats/client/global/stats")->get_node(1);

    my $id = $xp->find("ingress-discards", $n)->get_node(1);
    my $ed = $xp->find("egress-discards", $n)->get_node(1);
    $idTbl = DiscardTable($xp, $id, $idTbl, $name, "ingress");
    $edTbl = DiscardTable($xp, $ed, $edTbl, $name, "egress");
    }

    ## Check CPU utilization of all processes that are children of
    ## solacedaemon.
    my $user = ($rtr->{hostname} =~ m/^dev/) ? "" : "root\@";
    my $ppid = `ssh $user$rtr->{hostname} pgrep solacedaemon`;
    chomp($ppid);
    my $top = Solace::SysTest::Top::ForPPid($rtr->{hostname}, $ppid);

    ## For handling the defered creation of the table.
    my @hdrs = ("Name");
    my @vals = ($name);

    sub AbbrProc($) {
    my %abbr = ("xmlmanager" => "xml",
            "mgmtplane" => "mp",
            "trmmanager" => "trm",
            "watchdog" => "wd",
            "msgbusadapter" => "mba",
            "solcachemgr" => "sc",
            "dataplane" => "dp",
            "controlplane" => "cp",
            "solsnmp" => "snmp",
            "dataplane-linux" => "dpl",
    );
    if (exists($abbr{$_[0]})) { return $abbr{$_[0]}; }
    return substr($_[0], 0, 4);
    }

    foreach my $key (keys(%{$top})) {
    if (!defined($cpuTbl)) {
        push(@hdrs, AbbrProc($key));
    }
    push(@vals, $top->{$key}{qw(%CPU)});
    }
    if (!defined($cpuTbl)) {
    $cpuTbl = Solace::SysTest::Table::Get(\@hdrs);
    }
    $cpuTbl->load(\@vals);

    ($status, $xml) = Solace::SysTest::Router::SendSemp(
    $rtr, "<show><redundancy><detail/></redundancy></show>");
    if ($status =~ /200/) {
    my $xp = XML::XPath->new(xml => $xml);
    my $mate = Solace::SysTest::Router::GetNameFromHost($xp->findvalue("//show/redundancy/mate-router-name"));
    my @row = ("$name", "$mate");
    foreach my $vr ("primary", "backup") {
        my $red = $xp->findvalue("//$vr/status/activity");
        my $ms = $xp->findvalue("//$vr/status/detail/message-spool-status/internal/redundancy");
        push(@row, $red, $ms);
    }
    $redTbl->load(\@row);
    }

    return ($idTbl, $edTbl, $cpuTbl);
}

sub Router($$$$$) {
    my ($rtrs, $perfs, $clients, $args, $output_format) = @_;

    ## Use $args as our keys if provided.  That is, only audit a given
    ## subset of our routers.
    my @keys;
    if (@{$args}) {
        @keys = @{$args};
    }
    else {
        @keys = sort(keys(%{$rtrs}));
    }

    ## These tables are a little tricky, as until we start filling
    ## them in we don't know what their headings are.  The first users
    ## of them must detect that they are undef and initialize their
    ## headings.
    my $idTbl = undef;  ## Ingress discard table
    my $edTbl = undef;  ## Egress discard table
    my $cpuTbl = undef; ## Cpu usage table

    my $redTbl = Solace::SysTest::Table::Get(["Name",
                          "Mate", 
                          "Pri-Activity",
                          "Pri-MsgSpool",
                          "Bkup-Activity",
                          "Bkup-MsgSpool"]);

    foreach my $key (@keys) {
    if (exists($rtrs->{$key})) {
        ($idTbl, $edTbl, $cpuTbl) = 
        Router1($rtrs->{$key}, $idTbl, $edTbl, $cpuTbl, $redTbl);
    }
    else {
        Warn("Router '$key' does not exist");
    }
    }

    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Router Ingress Discard Stats", $idTbl);
    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Router Egress Discard Stats", $edTbl);
    print("\n");
    Solace::SysTest::Table::Display("Router CPU Utilization", $cpuTbl);
    print("\n");
    Solace::SysTest::Table::Display("Router Redundancy", $redTbl);
    print("\n");
}

sub Neighbor1($$$$$) {
    my ($rtr, $conn, $idTbl, $edTbl, $rateTbl) = @_;

    my $name = $rtr->{name};

    ## Collect connection status info for all neighbors of this
    ## router.
    my ($status, $xml) = Solace::SysTest::Router::SendSemp(
    $rtr, "<show><cspf><neighbor><physical-router-name>*</physical-router-name></neighbor></cspf></show>");
    if ($status =~ /200/) {
    my $xp = XML::XPath->new(xml => $xml);
    my @nbrs = $xp->findnodes("//neighbors/neighbor");
    
    foreach my $nbr (@nbrs) {
        my $n = $xp->findvalue("name", $nbr);
        my $status = $xp->findvalue("state", $nbr);

        $n = Solace::SysTest::Router::GetNameFromHost($n);

        if ($status && $status ne "Ok") {
        print("*** Neighbor connection from $name to $n is down\n");
        }
        ## Find the router whose hostname is $n.
        $conn->{$name}{$n} = $status;
    }
    }

    ## Collect discard stats and message count/rates for this router.

    ($status, $xml) = Solace::SysTest::Router::SendSemp(
    $rtr, "<show><stats><neighbor><detail/></neighbor></stats></show>");
    if ($status =~ /200/) {
    my $xp = XML::XPath->new(xml => $xml);
    my $n = $xp->find("//aggregate-stats")->get_node(1);

    my $id = $xp->find("ingress-discards", $n)->get_node(1);
    my $ed = $xp->find("egress-discards", $n)->get_node(1);
    $idTbl = DiscardTable($xp, $id, $idTbl, $name, "ingress");
    $edTbl = DiscardTable($xp, $ed, $edTbl, $name, "egress");

    my $rxCntCtrl = $xp->findvalue("messages-counts/control-messages/received", $n);
    my $rxCntData = $xp->findvalue("messages-counts/data-messages/received", $n);
    my $txCntCtrl = $xp->findvalue("messages-counts/control-messages/sent", $n);
    my $txCntData = $xp->findvalue("messages-counts/data-messages/sent", $n);

    my $rxRateCtrl = $xp->findvalue("average-message-rate-messages-per-60-seconds/control-rate/ingress", $n);
    my $rxRateData = $xp->findvalue("average-message-rate-messages-per-60-seconds/data-rate/ingress", $n);
    my $txRateCtrl = $xp->findvalue("average-message-rate-messages-per-60-seconds/control-rate/egress", $n);
    my $txRateData = $xp->findvalue("average-message-rate-messages-per-60-seconds/data-rate/egress", $n);

    $rateTbl->load([$name, 
            $rxCntCtrl, $rxRateCtrl, $rxCntData, $rxRateData, 
            $txCntCtrl, $txRateCtrl, $txCntData, $txRateData]);
    }

    return ($idTbl, $edTbl);
}

sub Neighbor($$$$$) {
    my ($rtrs, $perfs, $clients, $args, $output_format) = @_;

    ## Use $args as our keys if provided.  That is, only audit a given
    ## subset of our routers.
    my @keys;
    if (@{$args}) {
    @keys = @{$args};
    }
    else {
    @keys = sort(keys(%{$rtrs}));
    }

    ## These tables are a little tricky, as until we start filling
    ## them in we don't know what their headings are.  The first users
    ## of them must detect that they are undef and initialize their
    ## headings.
    my $idTbl = undef;    ## Ingress discard table
    my $edTbl = undef;    ## Egress discard table

    my $rateTbl = Solace::SysTest::Table::Get(["Name", 
                           "Rx Ctrl\nCount",
                           "Rx\nRate",
                           "Rx Data\nCount",
                           "Rx\nRate",
                           "Tx Ctrl\nCount",
                           "Tx\nRate",
                           "Tx Data\nCount",
                           "Tx\nRate"]);
    my %conn;

    foreach my $key (@keys) {
    if (exists($rtrs->{$key})) {
        ($idTbl, $edTbl) = Neighbor1($rtrs->{$key}, \%conn, $idTbl, $edTbl, 
                     $rateTbl);
    }
    else {
        Warn("Router '$key' does not exist");
    }
    }

    my $connTbl = Solace::SysTest::Table::Get(["Name", sort(keys(%conn))]);
    foreach my $key (sort(keys(%{$rtrs}))) {
    my @row = ($key);
    foreach my $key2 (sort(keys(%conn))) {
        if ($key eq $key2) {
        push(@row, "-");
        }
        else {
        push(@row, $conn{$key2}{$key});
        }
    }
    $connTbl->load(\@row);
    }

    print("\n");
    Solace::SysTest::Table::Display("Neighbor Connection Status", $connTbl);
    print("\n");
    Solace::SysTest::Table::Display("Neighbor Rates", $rateTbl);
    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Neighbor Ingress Discard Stats", 
                         $idTbl);
    print("\n");
    Solace::SysTest::Table::DisplayWithTotal("Neighbor Egress Discard Stats", 
                         $edTbl);
    print("\n");
}




sub Perfhost($$$$$) {
    # this proc is to show the running processes on the perfhosts
    # TODO: only grepping on "perf" and "SYSTEST_CLIENT" now. Any better way?
    my ($rtrs, $perfs, $clients, $args, $output_format) = @_;

    ## Use $args as our keys if provided.  That is, only audit a given
    ## subset of our perfhosts.
    my @keys;
    if (@{$args}) {
    @keys = @{$args};
    }
    else {
    @keys = sort(keys(%{$perfs}));
    }
    foreach my $perf (@keys) {
        my $dnsname = $perfs->{$perf}{dnsname};        
        my $user = ($perf =~ m/^dev/) ? "" : "root\@";
        my $grep1 = `ssh -n $user$dnsname 'ps -ef | grep perf'`;
        my $grep2 = `ssh -n $user$dnsname 'ps -ef | grep SYSTEST_CLIENT'`;
        print("\nOn perfhost $perf\n");
        print("\n$grep1\n");
        print("\n$grep2\n");
    }
}


END {
}

1;
 
