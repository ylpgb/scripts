#!/usr/bin/env run-router-script

%sub WaitRedundancyUp{
% my ($router) = $_[0];
% my ($status) = "Down";

% while ( $status ne "Up" ) { 
<%script router-num=$router type = "cli">
home
en
con
show redundancy

%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ( "$status" eq "Up" ) {
%    print "Redundancy is up";
%  } else {
%    print "Redundancy not up";
%    sleep 10;
%  }

% }
%}

% print "$rrsRouterNames[0] ...\n";
% print "$rrsRouterNames[1] ...\n";
