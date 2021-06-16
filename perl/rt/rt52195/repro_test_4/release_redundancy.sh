#!/usr/bin/env run-router-script
# 


% use Time::HiRes;
% RrsSetTimeout(9999999999); 

% my ($startTime, $elapsedTime);  

% my ($status) = "Down";

<%script type = "linux">
date

# Wait redundancy up on primary
% ($status) = "Down";
% $startTime = Time::HiRes::gettimeofday();

% while ( $status ne "Up" ) { 
<%script router-num="0" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ($status ne "Up" ) {
%    $elapsedTime = Time::HiRes::gettimeofday() - $startTime;
%    print "Redundancy on Primary not up yet after $elapsedTime sec\n";
%    sleep 30;
%  }
%}
% sleep 5;

# Shut/no shut message-spool on backup
<%script router-num="1" type = "cli" nowait="1">
<%if-prompt ".*Do you want to continue.*">y</%if-prompt>
home
en
con
hardware message-spool shutdown
% sleep 5;
no hardware message-spool shutdown
% sleep 5;

# Wait redundancy up on primary
% ($status) = "Down";
% $startTime = Time::HiRes::gettimeofday();

% while ( $status ne "Up" ) { 
<%script router-num="0" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ($status ne "Up" ) {
%    $elapsedTime = Time::HiRes::gettimeofday() - $startTime;
%    print "Redundancy on Primary not up yet after $elapsedTime sec\n";
%    sleep 30;
%  }
%}
% sleep 5;

# Release activity on primary
<%script router-num="0" type = "cli" nowait="1">
<%if-prompt ".*Do you want to continue.*">y</%if-prompt>
home
en
con
redundancy release
% sleep 5;
no redundancy release
% sleep 5;
no redundancy release

# Wait redundnacy up on backup
% ($status) = "Down";
% $startTime = Time::HiRes::gettimeofday();

% while ( $status ne "Up" ) { 
<%script router-num="1" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ($status ne "Up" ) {
%    $elapsedTime = Time::HiRes::gettimeofday() - $startTime;
%    print "Redundancy on Backup not up yet after $elapsedTime sec\n";
%    sleep 30;
%  }
%}
% sleep 5;


# Shut/no shut message-spool on primary
<%script router-num="0" type = "cli" nowait="1">
<%if-prompt ".*Do you want to continue.*">y</%if-prompt>
home
en
con
hardware message-spool shutdown
% sleep 5;
no hardware message-spool shutdown
% sleep 5;

# Wait redundnacy up on backup
% ($status) = "Down";
% $startTime = Time::HiRes::gettimeofday();

% while ( $status ne "Up" ) { 
<%script router-num="1" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ($status ne "Up" ) {
%    $elapsedTime = Time::HiRes::gettimeofday() - $startTime;
%    print "Redundancy on Backup not up yet after $elapsedTime sec\n";
%    sleep 30;
%  }
%}
% sleep 5;

# Release backup
<%script router-num="1" type = "cli" nowait="1">
<%if-prompt ".*Do you want to continue.*">y</%if-prompt>
home
en
con
redundancy release
% sleep 5;
no redundancy release
% sleep 5;
no redundancy release

# Wait redundnacy up on primary
% ($status) = "Down";
% $startTime = Time::HiRes::gettimeofday();

% while ( $status ne "Up" ) { 
<%script router-num="0" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Redundancy Status\s*:\s+([^\s]+)/);
%  if ($status ne "Up" ) {
%    $elapsedTime = Time::HiRes::gettimeofday() - $startTime;
%    print "Redundancy on Primary not up yet after $elapsedTime sec\n";
%    sleep 30;
%  }
%}
% sleep 5;

