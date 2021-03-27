#############################################################################
##
## Router
##
## This module contains tools to access and or control the router
##
#############################################################################

package Router;

use strict;
use warnings;
use Data::Dumper;
use Carp;
use base 'Exporter';

use Expect;
use Solace::Expect;
use JSON;

#############################################################################
## constants
##
#############################################################################
use constant {
    OK   => 0,
    FAIL => 1,
};

use constant DEFAULT_AUDIT_TXT_FILE => '/usr/sw/sol-platform-audit.txt';
use constant DEFAULT_AUDIT_FILE => '/usr/sw/sol-platform-audit.json';
use constant DEFAULT_LOCAL_TMP_DIR => '/home/public/Temp';
use constant DEFAULT_DEBUG_LOG_PATH => '/usr/sw/jail/logs';
use constant DEFAULT_KERNEL_LOG_PATH => '/usr/sw/jail/logs';


#############################################################################
## new - create object to interact with a router
##
#############################################################################
sub new {
    my $class = shift;
    my %args  = @_;

    map { croak "Missing required argument: $_" if !defined $args{$_}; } qw{ Router };

    my $SUPPORTED_SESSIONS = [ 'linux', 'cli', 'soldebug', 'sftp' ];
    my $sessions = {}; 
    foreach my $session (@{$args{Sessions}}) { 
        croak "Session type not supported: $session, must be one of " . join(', ', @{$SUPPORTED_SESSIONS}) if !grep(/$session/i, @{$SUPPORTED_SESSIONS}); 
        $sessions->{__normalizeSession($session)} = 1;
    }
    $args{Sessions} = (scalar keys %{$sessions}) ? [ keys %{$sessions} ] : [ 'Linux' ];

    my $self = { Router     => $args{Router},
                 Timeout    => $args{Timeout} || 10,
                 Username   => $args{Username} || 'admin',
                 Password   => $args{Password} || 'admin',
                 Debug      => $args{Debug} || 0,
                 Verbose    => $args{Verbose} || 0,
                 LogStdout  => $args{LogStdout} || 0,
                 Keyfile    => $args{Keyfile},
                 DieOnError => defined $args{DieOnError} ? $args{DieOnError} : 1,
               };

    foreach my $session (@{$args{Sessions}}) {
        $self->{Sessions}->{$session} = new Solace::Expect( router     => $self->{Router},
                                                            type       => lc($session),
                                                            timeout    => $self->{Timeout},
                                                            username   => $session eq 'Cli' ? 'admin' : $self->{Username},
                                                            password   => $session eq 'Cli' ? 'admin' : $self->{Password},
                                                            keyfile    => $self->{Keyfile},
                                                            debug      => $self->{Debug},
                                                            verbose    => $self->{Verbose},
                                                            log_stdout => $self->{LogStdout},
                                                            die_on_err => $self->{DieOnError},
                                                          );
        $self->{IpAddress} = $self->{Sessions}->{$session}->{conn}->{ip} if $self->{Sessions}->{$session}->{conn}->{ip} =~ /^\d/;
    }

    bless($self, $class);
    return $self;

} # new #


#############################################################################
## destroy - close object
##
#############################################################################
sub destroy {
    my ($self) = @_;

    foreach my $session (keys %{$self->{Sessions}}) { 
        $self->{Sessions}->{$session}->close() if $self->{Sessions}->{$session}->{Connected};
        $self->{Sessions}->{$session}->{Connected} = 0;
    }

} # destroy #


#############################################################################
## Unblessed helper utilites
##
#############################################################################
sub __normalizeSession { 
    my $session = shift();
    return ucfirst(lc($session));
}

sub __execCmdWithTimeout {
    my ($cmd, $timeout) = @_;
    $timeout = 30 if !defined $timeout;
 
    my ($pid, $pipe);
    eval {
       local $SIG{'ALRM'} = sub { die "Command timeout: $cmd\n"; };
       alarm($timeout);
       $pid = open($pipe, "$cmd |");
       while (<$pipe>) { ; }
       close($pipe);
       alarm(0);
    };
 
    if ($@ && $@ =~ /Command timeout/) {
       kill(15, $pid);
       close($pipe);
       print $@;
       return 1;
    }
 
    return $? / 256;
}

#############################################################################
## STATIC FUNCTION
## IsValidRouterName - Checks the router name for validity, accepts formats
## like 192.168.128.17, a17, or lab-128-17
##
##############################################################################
sub IsValidRouterName {
   my $name = shift();
   return 1 if $name =~ /^192\.168\.(?:1|128|129|130|131|132)\.\d{1,3}$/;
   return 1 if $name =~ /^lab-(?:1|128|129|130|131|132)-\d{1,3}$/;
   return 1 if $name =~ /^[a-e]\d{1,3}$/;
   return 0;
} # IsValidRouterName #


#############################################################################
## PingRouter - Check to see if router responds to ping
##
#############################################################################
sub PingRouter { 
    my ($self, %opts) = @_;
    $opts{Attempts} = 2 if !defined $opts{Attempts};

    return FAIL if !defined $self->{IpAddress};

    `ping -c $opts{Attempts} -i 0.2 -w 1 $self->{IpAddress}`;

    return $? ? FAIL : OK;

} # PingRouter #


#############################################################################
## DoAddKeyTo - Wrapper to add a timeout to addkeyto
##
#############################################################################
sub DoAddKeyTo {
   my ($self, %opts) = @_;
   $opts{AddKeyTo} = '/usr/local/bin/addkeyto' if !defined $opts{AddKeyTo} && -e '/usr/local/bin/addkeyto';
   $opts{AddKeyTo} = '/opt/soldev/devtools/bin/addkeyto' if !defined $opts{AddKeyTo} && -e '/opt/soldev/devtools/bin/addkeyto';
   return FAIL if !defined $opts{AddKeyTo};

   return __execCmdWithTimeout("$opts{AddKeyTo} $self->{IpAddress}", 30) ? FAIL : OK;

} # DoAddKeyTo #


#############################################################################
## ConnectToRouter - Connect to the router
##
#############################################################################
sub ConnectToRouter {
    my ($self, %opts) = @_;
    $opts{DoAddKeyTo} = 1 if !defined $opts{DoAddKeyTo};

    return FAIL if $opts{DoAddKeyTo} && $self->DoAddKeyTo() == FAIL;
 
    my $rc = OK;
 
    foreach my $session (keys %{$self->{Sessions}}) {
        my $conn = $self->{Sessions}->{$session}->connect($self->{Timeout});
        if (!defined $conn || !defined $conn->{exp}) {
            $rc = FAIL;
            $self->{Sessions}->{$session}->{Connected} = 0;
        } else { 
            $self->{Sessions}->{$session}->{Connected} = 1;
        }
    }

    return $rc;

} # ConnectToRouter #


#############################################################################
## SessionIsConnected - Returns OK if the supplied session is connected
##
#############################################################################
sub SessionIsConnected { 
    my ($self, $session) = @_;

    $session = __normalizeSession($session);

    return FAIL if !defined $self->{Sessions}->{$session} || !$self->{Sessions}->{$session}->{Connected};
    return OK;

}


#############################################################################
## SendCommand - Send an arbitrary command to the router
##
#############################################################################
sub SendCommand { 
   my ($self, $session, $cmd, %opts) = @_;
   
   $session = __normalizeSession($session); 
   return $self->{Sessions}->{$session}->send($cmd);

} # SendCommand #


#############################################################################
## RouterIsUp - Try any way to determine whether SolOS is actually up
##
#############################################################################
sub RouterIsUp {
    my ($self, %opts) = @_; 
    $opts{UseCliIfAvailable} = 1       if !defined $opts{UseCliIfAvailable};
    $opts{UseSoldebugIfAvailable} = 1  if !defined $opts{UseSoldebugIfAvailable};
    $opts{UseLinuxIfAvailable} = 1     if !defined $opts{UseLinuxIfAvailable};

    if ($opts{UseCliIfAvailable} && $self->SessionIsConnected('Cli') == OK) { 
        return OK if $self->SendCommand('Cli', 'show version', %opts) =~ /Current/m;
    }

    if ($opts{UseSoldebugIfAvailable} && $self->SessionIsConnected('Soldebug') == OK) { 
        return OK if $self->SendCommand('Soldebug', ':help', %opts) =~ /Debugger/m;
    }

    if ($opts{UseLinuxIfAvailable} && $self->SessionIsConnected('Linux') == OK) { 
        return OK if $self->SendCommand('Linux', 'service solace status', %opts) =~ /Monitoring SolOS processes/m;
    }

    return FAIL;

} # RouterIsUp #


#############################################################################
## FileExistsOnRouter - Checks to see if a file exists on the router
##
#############################################################################
sub FileExistsOnRouter { 
    my ($self, $file, %opts) = @_;
    $opts{RcPrefix} = 'linuxrc' if !defined $opts{RcPrefix};

    return FAIL if $self->SessionIsConnected('Linux') == FAIL;

    my $res = $self->SendCommand('Linux', "ls $file; echo $opts{RcPrefix}:\$?", %opts);
 
    return FAIL if $res !~ /$opts{RcPrefix}:(\d+)/m || $1 > 0;
    return OK;

} # FileExistsOnRouter #

    
#############################################################################
## CopyFileToRouter - Copies a file to the router
##
#############################################################################
sub CopyFileToRouter { 
    my ($self, $file, $dest, %opts) = @_;
    $dest = '/tmp' if !defined $dest;

    #TODO
    #if ($self->SessionIsConnected('Sftp') == OK) { 
    #}

    if ($self->SessionIsConnected('Linux') == OK) { 
        $opts{CmdLineArgs} = ''                 if !defined $opts{CmdLineArgs};
        $opts{UserName} = 'root'                if !defined $opts{UserName};

        $dest =~ s/\/\s*$//;
        return __execCmdWithTimeout("scp $opts{CmdLineArgs} $file $opts{UserName}\@$self->{IpAddress}:$dest", 40);
    }
  
    return FAIL;

} # CopyFileToRouter #


#############################################################################
## CopyFileToRouterAndExecute - Copies a file to the router and executes
## the file (presumed to be a script).. be sure you know what you are doing
## when calling this method
##
#############################################################################
sub CopyFileToRouterAndExecute { 
    my ($self, $file, $dest, %opts) = @_;
    $dest = '/tmp' if !defined $dest;
    $opts{CmdLineArgs} = ''  if !defined $opts{CmdLineArgs};
    $opts{RemoveFile} = 1    if !defined $opts{RemoveFile};

    return undef if $self->SessionIsConnected('Linux') == FAIL; 

    return undef if $self->CopyFileToRouter($file, $dest, %opts) == FAIL;

    $dest =~ s/\/\s*$//;
    $file =~ s/^.*\/(.+)/$1/;

    my $res = $self->SendCommand('Linux', "$dest/$file $opts{CmdLineArgs}");
    $self->SendCommand('Linux', "rm -f $dest/$file") if $opts{RemoveFile};
   
    return $res;

} # CopyFileToRouterAndExecute #


#############################################################################
## CopyFileFromRouter - Copies a file from the router
##
#############################################################################
sub CopyFileFromRouter {
    my ($self, $file, $dest, %opts) = @_;
    $dest = '/tmp' if !defined $dest;

    #TODO
    #if ($self->SessionIsConnected('Sftp') == OK) {
    #}

    if ($self->SessionIsConnected('Linux') == OK) {
        $opts{CmdLineArgs} = ''                 if !defined $opts{CmdLineArgs};
        $opts{UserName} = 'root'                if !defined $opts{UserName};

        $dest =~ s/\/\s*$//;
        return __execCmdWithTimeout("scp $opts{CmdLineArgs} $opts{UserName}\@$self->{IpAddress}:$file $dest", 40);
    }

    return FAIL;

} # CopyFileFromRouter #


#############################################################################
## RemoveFileFromRouter - Deletes a file from the router, obviously use 
## extreme caution when running this command
##
#############################################################################
sub RemoveFileFromRouter { 
    my ($self, $file, %opts) = @_;
    $opts{RcPrefix} = 'linuxrc' if !defined $opts{RcPrefix};
    $opts{CmdLineArgs} = ''                 if !defined $opts{CmdLineArgs};
    $opts{CmdLineArgs} .= ' -f'             if $opts{Force};
    $opts{CmdLineArgs} .= ' -r'             if $opts{Recursive};
    
    return FAIL if $self->SessionIsConnected('Linux') == FAIL;

    my $res = $self->SendCommand('Linux', "rm $opts{CmdLineArgs} $file; echo $opts{RcPrefix}:\$?", %opts);

    return FAIL if $res !~ /$opts{RcPrefix}:(\d+)/m || $1 > 0;
    return OK;

} # RemoveFileFromRouter #


##############################################################################
## FindLatestFileOnRouter - Returns the filename for the most recent file
## matching the supplied regex on the router
##
##############################################################################
sub FindLatestFileOnRouter {
    my ($self, $regex, %opts) = @_;

    return undef if $self->SessionIsConnected('Linux') == FAIL;

    chomp(my $file = $self->SendCommand('Linux', "ls -tr $regex | tail -n 1"), %opts);

    return undef if $file !~ /\w/ || $file =~ /No such file/;
    return $file;

} # FindLatestFileOnRouter #


##############################################################################
## CopyLatestFileFromRouter - Copies the most recent version of a file 
## matching the supplied regex from a router (returns the file name on 
## success)
##
##############################################################################
sub CopyLatestFileFromRouter {
    my ($self, $regex, $dest, %opts) = @_;
    $dest = '/tmp' if !defined $dest;

    #TODO
    #if ($self->SessionIsConnected('Sftp') == OK) {
    #}

    if ($self->SessionIsConnected('Linux') == OK) {
        $opts{CmdLineArgs} = ''                 if !defined $opts{CmdLineArgs};
        $opts{UserName} = 'root'                if !defined $opts{UserName};

        my $file = $self->FindLatestFileOnRouter($regex, %opts);
        return undef if !defined $file;

        return undef if $self->CopyFileFromRouter($file, $dest, %opts) == FAIL;
        $dest =~ s/\/+$//; 
        $file =~ s/^.+\/(.*)$/$dest\/$1/;
        return $file;
    }

    return FAIL; 

} # CopyLatestFileFromRouter #


#############################################################################
## GrepFileOnRouter - Search for a pattern in a specified file on the router
##
#############################################################################
sub GrepFileOnRouter {
    my ($self, $file, $regex, %opts) = @_;
    $opts{LinesBefore} = 0                       if !defined $opts{LinesBefore};
    $opts{LinesAfter} = 0                        if !defined $opts{LinesAfter};
    $opts{IgnoreCase} = 0                        if !defined $opts{IgnoreCase};
    $opts{CountOnly} = 0                         if !defined $opts{CountOnly};
    $opts{IgnoreLogger} = 0                      if !defined $opts{IgnoreLogger};

    return undef if $self->SessionIsConnected('Linux') == FAIL;

    my $cmd = "grep -e '$regex' $file" .
              " -B $opts{LinesBefore}" .
              " -A $opts{LinesAfter}" .
              ($opts{IgnoreCase} ? ' -i ' : '') .
              ($opts{CountOnly} ? ' -c ' : '') . 
              ($opts{IgnoreLogger} ? ' | grep -v logger' : '');

    return $self->SendCommand('Linux', $cmd, %opts);

} # GrepFileOnRouter #


#############################################################################
## ConnectSoldebugToProcess - Connects soldebug to a process
##
#############################################################################
sub ConnectSoldebugToProcess { 
    my ($self, $process, %opts) = @_;
    $process = lc($process);

    my $PROCESSES = { 
        cli           => 0,
        mgmtplane     => 1,
        controlplane  => 2,
        dataplane     => 3,
        watchdog      => 5,
        xmlmanager    => 7,
        solsnmp       => 8,
        trmmanager    => 9,
        msgbusadapter => 10,
        solcachemgr   => 11,
        smrp          => 12,
     }; 
         
     return FAIL if $self->SessionIsConnected('Soldebug') == FAIL;
     return FAIL if !defined $PROCESSES->{$process};

     my $res = $self->SendCommand('Soldebug', ":conn $PROCESSES->{$process}", %opts);
  
     return $res =~ /value = 0/m ? OK : FAIL;
     
} # ConnectSoldebugToProcess #


#############################################################################
## RunSoldebugCommand - Runs a soldebug command 
##
#############################################################################
sub RunSoldebugCommand { 
    my ($self, $cmd, %opts) = @_;
    
    return undef if $self->SessionIsConnected('Soldebug') == FAIL;

    return $self->SendCommand('Soldebug', $cmd, %opts);

} # RunSoldebugCommand #
    

#############################################################################
## RunCliCommand - Runs a CLI command
##
#############################################################################
sub RunCliCommand {
    my ($self, $cmd, %opts) = @_;

    return undef if $self->SessionIsConnected('Cli') == FAIL;

    return $self->SendCommand('Cli', $cmd, %opts);

} # RunCliCommand #


#############################################################################
## SearchDebugLog - Search the debug log for a pattern
##
#############################################################################
sub SearchDebugLog { 
    my ($self, $regex, %opts) = @_;
    $opts{DebugLogPath} = DEFAULT_DEBUG_LOG_PATH if !defined $opts{DebugLogPath};
    $opts{AllLogFiles} = 0                       if !defined $opts{AllLogFiles};
    $opts{LinesBefore} = 0                       if !defined $opts{LinesBefore};
    $opts{LinesAfter} = 0                        if !defined $opts{LinesAfter};
    $opts{IgnoreCase} = 0                        if !defined $opts{IgnoreCase};
    $opts{CountOnly} = 0                         if !defined $opts{CountOnly}; 
    $opts{IgnoreLogger} = 0                      if !defined $opts{IgnoreLogger};

    return $self->GrepFileOnRouter("$opts{DebugLogPath}/debug.log" . ($opts{AllLogFiles} ? '*' : ''), $regex, %opts);

} # SearchDebugLog # 


#############################################################################
## SearchKernelLog - Search the kernel log for a pattern
##
#############################################################################
sub SearchKernelLog {
    my ($self, $regex, %opts) = @_;
    $opts{KernelLogPath} = DEFAULT_KERNEL_LOG_PATH if !defined $opts{KernelLogPath};
    $opts{AllLogFiles} = 0                         if !defined $opts{AllLogFiles};
    $opts{LinesBefore} = 0                         if !defined $opts{LinesBefore};
    $opts{LinesAfter} = 0                          if !defined $opts{LinesAfter};
    $opts{IgnoreCase} = 0                          if !defined $opts{IgnoreCase};
    $opts{CountOnly} = 0                           if !defined $opts{CountOnly};
    $opts{IgnoreLogger} = 0                        if !defined $opts{IgnoreLogger};

    return $self->GrepFileOnRouter("$opts{KernelLogPath}/kernel.log" . ($opts{AllLogFiles} ? '*' : ''), $regex, %opts);

} # SearchKernelLog #


#############################################################################
## SearchAuditFile - Search the sol-platform-audit.txt file for a pattern
##
#############################################################################
sub SearchAuditFile {
    my ($self, $regex, %opts) = @_;
    $opts{AuditFile} = DEFAULT_AUDIT_TXT_FILE      if !defined $opts{AuditFile};
    $opts{LinesBefore} = 0                         if !defined $opts{LinesBefore};
    $opts{LinesAfter} = 0                          if !defined $opts{LinesAfter};
    $opts{IgnoreCase} = 0                          if !defined $opts{IgnoreCase};
    $opts{CountOnly} = 0                           if !defined $opts{CountOnly};

    return $self->GrepFileOnRouter($opts{AuditFile}, $regex, %opts);

} # SearchAuditFile #


#############################################################################
## GetSolPlatformAuditInfo - Extracts sol-platform-audit information from 
## JSON file (supports 7.1 formats and beyond)
##
#############################################################################
sub GetSolPlatformAuditInfo { 
    my ($self, %opts) = @_;
    $opts{AuditFile} = DEFAULT_AUDIT_FILE   if !defined $opts{AuditFile};
    $opts{RcPrefix} = 'linuxrc'             if !defined $opts{RcPrefix};
    $opts{DestDir} = DEFAULT_LOCAL_TMP_DIR  if !defined $opts{DestDir};
    $opts{RemoveFile} = 1                   if !defined $opts{RemoveFile};

    return undef if $self->SessionIsConnected('Linux') == FAIL;

    my $res = $self->SendCommand('Linux', "grep AuditMode $opts{AuditFile}; echo $opts{RcPrefix}:\$?", %opts);
    return undef if $res !~ /$opts{RcPrefix}:(\d+)/m || $1 > 0;

    $opts{DestDir} =~ s/\/+$//;
    return undef if $self->CopyFileFromRouter($opts{AuditFile}, $opts{DestDir}, %opts) == FAIL;
   
    my $json;

    my $fh;
    $opts{AuditFile} =~ s/^.*\/(.+)/$1/;
    if (-e "$opts{DestDir}/$opts{AuditFile}" && open($fh, "$opts{DestDir}/$opts{AuditFile}")) {
        local $/;
        $json = decode_json(<$fh>);
        close($fh);
    }

    `rm -f $opts{DestDir}/$opts{AuditFile}` if $opts{RemoveFile};

    return $json;

} # GetSolPlatformAuditInfo #

    

#sub copyAndExecuteScript { 
#   my ($self, $script, %opts) = @_;
#
#   $opts{ScpCommand} = DEFAULT_SCP_COMMAND if !defined $opts{ScpCommand};
#   $opts{DestDir} = '/tmp'                 if !defined $opts{DestDir};
#   $opts{CmdLineArgs} = ''                 if !defined $opts{CmdLineArgs};
#   $opts{CopyOnly} = 0                     if !defined $opts{CopyOnly};
#   $opts{UserName} = 'root'                if !defined $opts{UserName};
#   $opts{RemoveAfter} = 1                  if !defined $opts{RemoveAfter};
#
#   $opts{DestDir} =~ s/\/\s*$//;
#   return undef if $self->execCmdWithTimeout("$opts{ScpCommand} $script $opts{UserName}\@$self->{session}->{conn}->{ip}:$opts{DestDir}", 40);
#
#   return undef if $opts{CopyOnly};
#
#   $script =~ s/^.+\/(.+?)$/$1/;
#   my $res = $self->sendCommand("$opts{DestDir}/$script $opts{CmdLineArgs}");
#   $self->sendCommand("rm -f $opts{DestDir}/$script") if $opts{RemoveAfter};
#
#   return $res;
#
#} # copyAndExecuteScript #
#
#

1;
