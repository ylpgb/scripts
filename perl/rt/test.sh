#!/usr/bin/env run-router-script

% my ($status) = "Down";


# Reset message-spoon on primary and backup
<%script router-num="1" type = "cli">
home
en
con
redundancy shutdown
hardware message-spool shut
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
end
admin
system
message-spool
reset
end
con
no redundancy shutdown
no hardware message-spool shutdown

sleep 5

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
 

 
