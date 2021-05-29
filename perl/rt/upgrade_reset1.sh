#!/usr/bin/env run-router-script
# 

% my ($status) = "Down";

<%script type = "linux">
date

# Wait redundancy up on primary
% ($status) = "Down";

% while ( $status ne "Up" ) { 
<%script router-num="0" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ($status ne "Up" ) {
%    print "Redundancy on Primary not up yet\n";
%    sleep 30;
%  }
%}
% sleep 5;

# Delete 9.9.0.23 db on backup
<%script router-num="1" type = "linux">
<%if-prompt "password for root:">solace1</%if-prompt>
sudo rm -rf /usr/sw/var/soltr_9.9.0.23

# Upgrade backup
<%script router-num="1" type = "cli" nowait="1">
<%if-prompt "Do you want to continue">y</%if-prompt>
home
en
boot 9.9.0.23
% sleep 5;

