package Solace::Sm::Cmd::Router::Restart;

use warnings;
use base Solace::Sm::Cmd::Router;

use Solace::Sm::Env;
use Solace::Sm::Cmd::Router::Stop;
use Solace::Sm::Cmd::Router::Start;
use Solace::Sm::Cmd::Router::Init;

## sub doRun() {
##   my $self = shift();
##   my @rtrs = $self->getRouters();
## 
##   ## Stop all routers.
##   foreach my $rtr (@rtrs) {
##     my $pid = $rtr->getPid();
##     if ($pid) {
##       ## Stop the router.  Use the given router-hosts.
##       my %stopArgs = (router_hosts => $self->{args}{router_hosts},
## 		      quiet => $self->{args}{quiet},
## 		      verbose => $self->{args}{verbose},
## 		      debug => $self->{args}{debug}
## 		     );
##       my $cmd = Solace::Sm::Cmd::Router::Stop->new(\%stopArgs);
##       $cmd->doRunSingle($rtr);
##     }
##   }
## 
##   ## Wait for each to stop in order, and start them as soon as they
##   ## do.
##   foreach my $rtr (@rtrs) {
##     while ($rtr->getPid()) {
##       sleep(1);
##     }
##     my $cmd = Solace::Sm::Cmd::Router::Start->new($self->{args});
##     $cmd->doRunSingle($rtr);
##   }
## 
##   ## Initialize any routers started if needed.
##   if ($self->{args}{init}) {
##     foreach my $rtr (@rtrs) {
##       my $cmd = Solace::Sm::Cmd::Router::Init->new($self->{args});
##       $cmd->doRunSingle($rtr);
##     }
##   }
##   elsif ($self->{args}{wait}) {
##     foreach my $rtr (@rtrs) {
##       ## Wait longer for production routers -- they take longer to start
##       ## up.
##       my $retryCount = $rtr->isDev() ? 10 : 30;
##       $self->poll($rtr, $retryCount);
##     }
##   }
## }

sub doRun() {
  my $self = shift();
  my @rtrs = $self->getRouters();

  ## Stop all routers.
  my %stopArgs = (router_hosts => $self->{args}{router_hosts},
		  router_number_range => $self->{args}{router_number_range},
		  mode => $self->{args}{mode},
		  sm_dir => $self->{args}{sm_dir},
		  wait => 1,
		  quiet => $self->{args}{quiet},
		  verbose => $self->{args}{verbose},
		  debug => $self->{args}{debug}
		 );
  my $stopCmd = Solace::Sm::Cmd::Router::Stop->new(\%stopArgs);
  $stopCmd->doRun();

  ## Restart implies --no-init unless --no-db was given.
  if ($self->{args}{db}) {
    $self->{args}{init} = 0;
  }

  ## Start all routers.
  my $startCmd = Solace::Sm::Cmd::Router::Start->new($self->{args});
  $startCmd->doRun();
}

1;


