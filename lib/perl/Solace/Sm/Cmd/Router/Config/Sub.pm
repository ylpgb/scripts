package Solace::Sm::Cmd::Router::Config::Sub;

use warnings;
use base Solace::Sm::Cmd::PubSub;

sub getType() {
  return "subscriber";
}

1;


