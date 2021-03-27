package Solace::Sm::Cmd::Router::Init;

use warnings;
use base Solace::Sm::Cmd::Router;

use Solace::Sm::Env;

sub doRunSingle($) {
  my $self = shift();
  my $rtr = shift();

  $self->info("Initing router " . $rtr->getName() . "...");

  ## Wait longer for production routers -- they take longer to start
  ## up.
  my $retryCount = $rtr->isDev() ? 10 : 30;
  $self->poll($rtr, $retryCount);

  ## Send some initial config to router which is generally useful for
  ## developers on small-mem.

  my $lagIntf = $rtr->isDev() ? "1/1/lag1" : "1/6/lag1";

  ## Configure our linecard msg-bb vrf (ip-address and default route).
  my $cidraddr = getMsgBbCidr($rtr);
  $self->sempRpc($rtr, "<create><interface><phy-interface>${lagIntf}</phy-interface><mode>lacp</mode></interface></create>");
  $self->sempRpc($rtr, "<interface><phy-interface>${lagIntf}</phy-interface><no><shutdown></shutdown></no></interface>");
  $self->sempRpc($rtr, "<ip><vrf><name>msg-backbone</name><route><default/><ip-addr>192.168.160.1</ip-addr></route></vrf></ip>");
  $self->sempRpc($rtr, "<ip><vrf><name>msg-backbone</name><create><interface><ip-interface>${lagIntf}:1</ip-interface><static/></interface></create></vrf></ip>");
  $self->sempRpc($rtr, "<ip><vrf><name>msg-backbone</name><interface><ip-interface>${lagIntf}:1</ip-interface><ip-address><cidr-addr>$cidraddr</cidr-addr></ip-address></interface></vrf></ip>");
  $self->sempRpc($rtr, "<ip><vrf><name>msg-backbone</name><interface><ip-interface>${lagIntf}:1</ip-interface><no><shutdown/></no></interface></vrf></ip>");

  ## The following is not supported or relevent to TMA mode.
  ##
  if ($rtr->getMode() ne "tma") {
    ## Disable authentication.
    if ($rtr->getMode() eq "solos") {
      $self->sempRpc($rtr, "<authentication><user-class><http/><auth-type><none/></auth-type></user-class></authentication>");
      $self->sempRpc($rtr, "<authentication><user-class><pubsub/><auth-type><none/></auth-type></user-class></authentication>");
    }
    if ($rtr->getMode() eq "soltr") {
      $self->sempRpc($rtr, "<message-vpn><vpn-name>default</vpn-name><authentication><user-class><client/><basic><auth-type><none/></auth-type></basic></user-class></authentication></message-vpn>");
      $self->sempRpc($rtr, "<message-vpn><vpn-name>default</vpn-name><export-policy><export-subscriptions/></export-policy></message-vpn>");
      $self->sempRpc($rtr, "<message-vpn><vpn-name>default</vpn-name><no><shutdown/></no></message-vpn>");
      $self->sempRpc($rtr, "<client-username><username>default</username><vpn-name>default</vpn-name><no><shutdown/></no></client-username>");
## Temporarily disabled until d30cfg merges with trunk.
##      $self->sempRpc($rtr, "<client-profile><name>default</name><vpn-name>default</vpn-name><allow-bridge-connections/></client-profile>");
    }

    ## Configure the routing interface.  SMF service must be shutdown
    ## to do this.
    $self->sempRpc($rtr, "<service><smf><shutdown/></smf></service>");
    $self->sempRpc($rtr, "<routing><interface><phy-interface>${lagIntf}</phy-interface></interface></routing>");
    $self->sempRpc($rtr, "<service><smf><no><shutdown/></no></smf></service>");
    if ($rtr->getMode() eq "soltr") {
	$self->sempRpc($rtr, "<routing><no><shutdown/></no></routing>");
    }

    ## Add some closed-user-groups to profiles.
    if ($rtr->getMode() eq "solos") {
      $self->sempRpc($rtr, "<publisher-profile><name>default</name><closed-user-group><group-num>1</group-num></closed-user-group></publisher-profile>");
      $self->sempRpc($rtr, "<subscriber-profile><name>default</name><closed-user-group><group-num>1</group-num></closed-user-group></subscriber-profile>");
    }

    ## Start listening on ports.
    my $smfPort = $rtr->getPort("tcp");
    my $smfCtrlPort = $smfPort + 1;
    my $smfCompressedPort = $smfPort + 2;
    $self->sempRpc($rtr, "<service><smf><shutdown/></smf></service>");
    $self->sempRpc($rtr, "<service><smf><listen-port><port>$smfPort</port></listen-port></smf></service>");

    if ($rtr->getMode() eq "soltr") {
	  $self->sempRpc($rtr, "<service><smf><listen-port><port>$smfCompressedPort</port><compressed/></listen-port></smf></service>");
      $self->sempRpc($rtr, "<service><smf><listen-port><port>$smfCtrlPort</port><routing-control/></listen-port></smf></service>");
    }

    $self->sempRpc($rtr, "<service><smf><no><shutdown/></no></smf></service>");

  }
  else {
    ## Start listening on ports.
    my $rvPort = $rtr->getPort("tcp");
    $self->sempRpc($rtr, "<rv><shutdown/></rv>");
    $self->sempRpc($rtr, "<rv><listen-port><port>$rvPort</port></listen-port></rv>");
    $self->sempRpc($rtr, "<rv><no><shutdown/></no></rv>");
  }

  ## Configure AD if needed.
  if ($self->{args}{ad}) {
      ## Enable message-spool.
      $self->sempRpc($rtr, "<hardware><message-spool><internal-disk/></message-spool></hardware>");
      $self->sempRpc($rtr, "<hardware><message-spool><no><shutdown><primary/></shutdown></no></message-spool></hardware>");

      ## Allow signaled AD stuff.
      $self->sempRpc($rtr, "<client-profile><name>default</name><vpn-name>default</vpn-name><message-spool><allow-guaranteed-endpoint-create/></message-spool></client-profile>");
      $self->sempRpc($rtr, "<client-profile><name>default</name><vpn-name>default</vpn-name><message-spool><allow-guaranteed-message-send/></message-spool></client-profile>");
      $self->sempRpc($rtr, "<client-profile><name>default</name><vpn-name>default</vpn-name><message-spool><allow-guaranteed-message-receive/></message-spool></client-profile>");
      $self->sempRpc($rtr, "<client-profile><name>default</name><vpn-name>default</vpn-name><message-spool><allow-transacted-sessions/></message-spool></client-profile>");

      ## Give ourselves some spool-usage.
      $self->sempRpc($rtr, "<message-spool><vpn-name>default</vpn-name><max-spool-usage><size>80000</size></max-spool-usage></message-spool>");
  }
}

sub getMsgBbCidr($) {
  my $rtr = shift();
  my $ip = $rtr->getMsgBbIp();

  if ($rtr->isDev()) {
    return $ip . "/24";
  }
  else {
    return $ip . "/20";
  }
}

1;


