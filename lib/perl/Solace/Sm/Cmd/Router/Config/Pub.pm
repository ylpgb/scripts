package Solace::Sm::Cmd::Router::Config::Pub;

use warnings;
use base Solace::Sm::Cmd::PubSub;

sub getType() {
  return "publisher";
}

1;


