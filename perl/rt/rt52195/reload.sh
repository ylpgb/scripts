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

# Reload primary
<%script router-num="0" type = "cli">
<%if-prompt "Do you want to continue.*">y</%if-prompt>
home
en
reload
% sleep 5;

# Wait redundnacy up on backup
% ($status) = "Down";

% while ( $status ne "Up" ) { 
<%script router-num="1" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ($status ne "Up" ) {
%    print "Redundancy on Backup not up yet\n";
%    sleep 30;
%  }
%}
% sleep 5;

# Release backup
<%script router-num="1" type = "cli">
<%if-prompt "Do you want to continue.*">y</%if-prompt>
home
en
reload
% sleep 5;

# Wait redundnacy up on primary
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

