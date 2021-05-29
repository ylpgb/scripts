#!/usr/bin/env run-router-script
# 

% my ($status) = "Down";

# It will take time for backup to upgrade and redundancy to be down on primary. So wait for 60s
% sleep 60;

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

# Release primary
<%script router-num="0" type = "cli">
<%if-prompt "Do you want to continue.*">y</%if-prompt>
home
en
con
redundancy release
no redundancy release
% sleep 5;

# Wait AD-Active on backup
% ($status) = "Down";

% while ( $status ne "AD-Active" ) { 
<%script router-num="1" type = "cli">
home
en
con
no service msg-backbone shut
show message-spool
%  ($status) = ($rrsLastResult =~ /Operational Status\s*:\s+([^\s]+)/);
%  if ($status ne "AD-Active" ) {
%    print "Message-spool on backup is not AD-Active yet\n";
%    sleep 30;
%  }
%}
% sleep 5;

# Reset backup to 9.8.0.12
<%script router-num="1" type = "cli">
<%if-prompt "Do you want to continue">y</%if-prompt>
home
en
con
service msg-backbone shut
hardware message-spool shut
end
boot 9.8.0.12

