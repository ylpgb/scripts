package Solace::SysTest::Router;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use XML::XPath;

use Solace::SysTest::Log qw(Debug Info Warn Error);
use Solace::SysTest::ConfigFile;

BEGIN {
}

our $userAgent;
our %hostToName;

sub SendSemp($$;$) {
    my ($rtr, $semp, $key) = @_;
    Debug("Sending SEMP to " . $rtr->{hostname} . ": $semp");
    if (defined $key) {
        Debug("This is for router $key");
    }
    if (!$userAgent) {
    $userAgent = LWP::UserAgent->new(timeout => 120);
    }

    my $port = $rtr->{"port-semp"} ? $rtr->{"port-semp"} : 80;

    my $uri = "http://" . $rtr->{hostname} . ":${port}/SEMP";
    my $req = HTTP::Request->new(POST => "$uri");
    my $ver = $rtr->{"semp-ver"} ? $rtr->{"semp-ver"} : "soltr/5_3";
    $req->authorization_basic("admin", "admin");
    $req->content("<rpc semp-version='" . $ver . "'>" . $semp . "</rpc>");
    Debug("Request:" . $req->as_string());
    my $resp = $userAgent->request($req);
    Debug("Response:" . $resp->as_string());

    if ($resp->status_line() !~ m/^200/) {
    Info("Request failed: " . $resp->status_line());
    }

    return ($resp->status_line(), $resp->content());
}

sub GetNameFromHost($) {
    if (exists($hostToName{$_[0]})) {
    return $hostToName{$_[0]};
    }
    return "";
}

sub ReverseDNSLookup($) {
    my $ipaddr = shift;
    my $foo = `ssh root\@perf-130-165 dig -x $ipaddr +short`;
    if ($foo) {
        $foo =~ /([a-z0-9]+)\./;    
        return $1;
    } else {
        die "couldn't get a name for $ipaddr, got $foo\n";
    }
}

sub Init($$) {
    my ($run_init, $cloud) = @_;
    my $rtrs = "";
    if ($cloud) {
        $rtrs = Solace::SysTest::ConfigFile::Init("router","router-cloud");
    } else {
        $rtrs = Solace::SysTest::ConfigFile::Init("router","router");
    }

    ## Select defaults for anything not specified.
    foreach my $key (sort(keys(%{$rtrs}))) {
    $hostToName{$rtrs->{$key}{hostname}} = $key;
    }

    ## Discover what we can about the routers.
    foreach my $key (sort(keys(%{$rtrs}))) {
        Debug("Initting $key\n");
        ## Get version info.
        my $version = "unknown";
        my $uptime = "unknown";
        my ($status, $xml) = SendSemp($rtrs->{$key}, "<show><version/></show>", $key);
        if ($status =~ /200/) {
            my $xp = XML::XPath->new(xml => $xml);
            $version = $xp->findnodes("//show/version/current-load");
            my $days = $xp->findnodes("//show/version/uptime/days");
            my $hrs = $xp->findnodes("//show/version/uptime/hours");
            my $mins = $xp->findnodes("//show/version/uptime/mins");
            my $secs = $xp->findnodes("//show/version/uptime/secs");
            $uptime = "${days}d ${hrs}h ${mins}m ${secs}s";
        }
        $rtrs->{$key}{version} = $version;
        $rtrs->{$key}{uptime} = $uptime;
        ## Get msg-backbone IP config.
        ($status, $xml) = SendSemp($rtrs->{$key}, "<show><ip><vrf><name>msg-backbone</name></vrf></ip></show>");
        if ($status =~ /200/) {
        my $xp = XML::XPath->new(xml => $xml);
        foreach my $vr ("static", "primary", "backup") {
        my $ip = $xp->findnodes("//intf-element[v-router='${vr}']/ip-addr");
        if ($ip) {
                    $ip =~ s/\/.*//;  # strip trailing /nn of CIDR notation
                    $rtrs->{$key}{"ip-msgbb-$vr"} = $ip;
                    $rtrs->{$key}{"host-msgbb-$vr"} = ReverseDNSLookup($ip);
                } else {
                    Warn("No " . $vr . " ip-addr for " . $key);
                }
        }
        }
        ## Get SMF listen ports.
        ($status, $xml) = SendSemp($rtrs->{$key}, "<show><service/></show>");
        if (!exists($rtrs->{$key}{"overwrite"})) {
            if ($status =~ /200/) {
                my $xp = XML::XPath->new(xml => $xml);
                my $port = $xp->findnodes("//service[name='SMF']/listen-port");
                $rtrs->{$key}{"port-smf"} = $port;
                $port = $xp->findnodes("//service[name='SMF']/compression-listen-port");
                $rtrs->{$key}{"port-smfc"} = $port;
                $port = $xp->findnodes("//service[name='WEB']/listen-port");
                $rtrs->{$key}{"port-web"} = $port;
                $port = $xp->findnodes("//service[name='SMF']/ssl/listen-port");
                $rtrs->{$key}{"port-ssl"} = $port;
                $port = $xp->findnodes("//service[name='WEB']/ssl/listen-port");
                $rtrs->{$key}{"port-ssl-web"} = $port;
            }
        }

        ## Figure our our mate.
        ($status, $xml) = Solace::SysTest::Router::SendSemp(
            $rtrs->{$key}, "<show><redundancy/></show>");
        if ($status =~ /200/) {
            my $xp = XML::XPath->new(xml => $xml);
            my $mate = Solace::SysTest::Router::GetNameFromHost
        ($xp->findvalue("//show/redundancy/mate-router-name"));
            $rtrs->{$key}{"mate"} = $mate;
        } else {
            print "Redundancy down on $key : semp call returned $status\n";
        }
        #Prep the system clearing queues, deleting messages, and clearing stop-lost
        if ($run_init) {
            my $rtr = $rtrs->{$key};
            my $hostname = $rtr->{"hostname"};
            my $prep_args = exists($rtr->{"prep-args"}) ? $rtr->{"prep-args"} : "";
            my $systemtestdir = Solace::SysTest::Common::GetSystemTestDir();
            print "preparing $hostname (for router $key)\n";
            print `$systemtestdir/rs-systest-prep $hostname $prep_args --timeout 120`;
        }
    }
    return $rtrs;
}

sub Analyze($) {
    my $run_analyze = shift;
    my $rtrs = Solace::SysTest::ConfigFile::Init("router","router");

    ## Set hostname
    foreach my $key (sort(keys(%{$rtrs}))) {
    $hostToName{$rtrs->{$key}{hostname}} = $key;
    }

    if ($run_analyze) {
        #Start message deletion
        foreach my $key (sort(keys(%{$rtrs}))) {
            foreach my $vpn_name (split(",",$rtrs->{"vpn-list"})) {
                my $semp = <<END;
                <admin>
                  <message-spool>
                    <vpn-name>$vpn_name</vpn-name>
                    <delete-messages>
                      <queue-name>*</queue-name>
                    </delete-messages>
                  </message-spool>
                </admin>
END
               my ($status, $xml) = Solace::SysTest::Router::SendSemp(
                   $rtrs->{$key},$semp);
            }
        }

        foreach my $key (sort(keys(%{$rtrs}))) {
            #Prep the system clearing queues, deleting messages, and clearing stop-lost
            my $rtr = $rtrs->{$key};
            my $hostname = $rtr->{"hostname"};
            my $post_args = exists($rtr->{"post-args"}) ? $rtr->{"post-args"} : "";
            if ($post_args) {
                my $systemtestdir = Solace::SysTest::Common::GetSystemTestDir();
                print "Analyzing $hostname\n";
                # my $pid = fork();
                # if ($pid == 0) {
                #     printf("post: $hostname\n");
                # } else {
                     print `$systemtestdir/rs-systest-post $hostname $post_args --timeout 120`;
                # }
            }
        }
        
    }
    return $rtrs;
}

sub Display($) {
    my ($rtr) = @_;
    Solace::SysTest::ConfigFile::Display("Router", $rtr);
}


sub Clear() {
    my $rtrs = Solace::SysTest::ConfigFile::Init("router","router");
    my $systemtestdir = Solace::SysTest::Common::GetSystemTestDir();
    ## Set hostname
    foreach my $key (sort(keys(%{$rtrs}))) {
        $hostToName{$rtrs->{$key}{hostname}} = $key;
    }
    foreach my $key (sort(keys(%{$rtrs}))) {
        my $rtr = $rtrs->{$key};
        my $hostname = $rtr->{"hostname"};
        print "clearing $hostname\n";
        print `$systemtestdir/rs-systest-clear $hostname --timeout 120`;
    }
}

END {
}

1;
