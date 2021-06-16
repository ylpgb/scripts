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
%    sleep 10;
%  }
%}
% sleep 5;

# Shutdown message-spool on primary
<%script router-num="0" type = "cli" nowait="1">
<%if-prompt "Do you want to continue">y</%if-prompt>
home
en
configure
show message-spool
hardware message-spool shutdown
% sleep 10;
no hardware message-spool shutdown
% sleep 5;

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
%    sleep 10;
%  }
%}
% sleep 5;
