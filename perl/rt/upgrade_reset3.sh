#!/usr/bin/env run-router-script

% my ($status) = "Down";

# It will take time for backup to reset. Wait for 60s
% sleep 600;

# Wait for backup to boot up
% while ( $status ne "Enabled" ) { 
<%script router-num="1" type = "cli">
home
en
con
show redundancy
%  ($status) = ($rrsLastResult =~ /Configuration Status\s*:\s+([^\s]+)/);
%  if ($status ne "Enabled" ) {
%    print "Backup not up yet\n";
%    sleep 30;
%  }
%}

# Reset message-spoon on primary and backup
<%script router-num="0" type = "cli">
home
en
con
redundancy shutdown
hardware message-spool shut
% sleep 5;
end
admin
system
message-spool
reset
end
con
no redundancy shutdown
no hardware message-spool shutdown


<%script router-num="1" type = "cli">
home
en
con
redundancy shutdown
hardware message-spool shut
% sleep 5;
end
admin
system
message-spool
reset
end
con
no redundancy shutdown
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
%    sleep 30;
%  }
%}
% sleep 5;
 

 
