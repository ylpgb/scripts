#############################################################################
##
## Solace::LogParser
##
## This module will accept a line of debug or event log, and return a
## hash with all of the successfully parsed fields, or an empty hash
## if parsing fails.
##
#############################################################################

package Solace::LogParser;

use strict;
use warnings;
use Data::Dumper;
# use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# @ISA = qw(Exporter);
# @EXPORT = ();
# @EXPORT_OK = qw(parseLine cleanMsg);
# %EXPORT_TAGS = (DEFAULT =>[qw(&parseLine &cleanMsg)]);


##############################################################################
## parseLine
##
## Takes a line of a debug log or event log, and parses it into named fields.
##
## Returns a hash of said fields.  Buyer beware!  Not all logs have
## the same fields!  So if you are going to look for one of the more
## obscure fields, it might not be in there!
##
## Type, Thread, File, User, Router, and Exec seem to be the riskiest
## culprits.
##
##############################################################################

sub parseLine {
    my $line = shift;
    my $noWarn = shift;

    my ($date, $time, $level, $router, $user, $pid, $dir, $file, $type, $thread, $msg) =
        ($line =~ /(\d+-\d+-\d+)T                    # Date
                   (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+     # Time
                   \s+
                   <[\w\d]+\.(\w+)>\s*([\w\d\-_]+)   # Level
                   \s+
                   ([\w\d\-_]+)                      # User
                   \[(\d+)\]:?                       # PID
                   \s+
                   ([\w\d\/_\-\.]+)?                  # Directory
                   \s+
                   ([\w\d\/_\-\.]+:\d+)              # File
                   \s+
                   \(([\w\_\-\d]+)\s*-\s*[\dxa-fA-F]+\) # Type
                   \s+
                   ([^\s]+)                          # Thread
                   \s+
                   (.+)                              # Msg
                   /x);
    if (!$dir) {$dir = '.'}
    $router = "n/a";

    if (!$msg || $msg =~ /^\s*$/) {
      ($date, $time, $level, $router, $user, $pid, $dir, $file, $type, $thread, $msg) =
          ($line =~ /(\d+-\d+-\d+)T                    # Date
                     (\d+:\d+:\d+.?\d{0,6})[\+\-][\d:]+         # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*([\w\d\-_]+)   # Level
                     \s+
                     ([\w\d\-_]+):?                    # User
                     (?:\[(\d+)\]:)?                   # PID
                     \s+
                     ([\w\d\/_\-\.]+)?                 # Directory
                     \s+
                     ([\w\d\/_\-\.]+:\d+)              # File
                     \s+
                     \(([\w\_\-\d]+)\s*-\s*[\dxa-fA-F]+\) # Type
                     \s+
                     ([^\s]+)                          # Thread
                     \s+
                     (.+)                              # Msg
                     /x);
      if (!$dir) {$dir = '.'}
      if (!$pid) {$pid = "n/a"}
      $router = "n/a";
    }

    if (!$msg || $msg =~ /^\s*$/) {
      ($date, $time, $router, $user, $pid, $dir, $file, $type, $thread, $msg) =
          ($line =~ /(\d+-\d+-\d+)T                     # Date
                     (\d+:\d+:\d+.?\d{0,6})[\+\-][\d:]+ # Time
                     \s+
                     ([^\s]+)                           # Hostname
                     \s+
                     ([\w\d\-_]+):?                     # User
                     (?:\[(\d+)\]:)?                    # PID
                     \s+
                     ([\w\d\/_\-\.]+)?                  # Directory
                     \s+
                     ([\w\d\/_\-\.]+:\d+)               # File
                     \s+
                     \(([\w\_\-\d]+)\s*-\s*[\dxa-fA-F]+\) # Type
                     \s+
                     ([^\s]+)                           # Thread
                     \s+
                     (.+)                               # Msg
                     /x);
      $level = 'info' if $msg;
      if (!$dir) {$dir = '.'}
      if (!$pid) {$pid = "n/a"}
    }

    if (!$msg || $msg =~ /^\s*$/) {
      ($date, $time, $router, $msg) =
          ($line =~ /(\d+-\d+-\d+)T                     # Date
                     (\d+:\d+:\d+.?\d{0,6})[\+\-][\d:]+ # Time
                     \s+
                     ([^\s]+)                           # Hostname
                     \s+
                     event:                             # event:
                     \s+
                     (.+)                               # Msg
                     /x);
      if ($msg) {
        $level  = 'info';
        $user   = '';
        $pid    = 'n/a';
        $dir    = 'n/a';
        $file   = '';
        $type   = 'Event';
        $thread = '';
      }
      if (!$dir) {$dir = '.'}
      if (!$pid) {$pid = "n/a"}
    }

    if (!$msg || $msg =~ /^\s*$/) {
      ($date, $time, $level, $router, $user, $pid, $dir, $file, $type, $thread, $msg) =
          ($line =~ /(\d+-\d+-\d+)T                    # Date
                     (\d+:\d+:\d+.?\d{0,6})[\+\-][\d:]+         # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*([\w\d\-_]+)   # Level
                     \s+
                     ([\w\d\-_]+):?                    # User
                     (?:\[(\d+)\]:)?                   # PID
                     \s+
                     ([\w\d\/_\-\.]+)?                 # Directory
                     \s+
                     ([\w\d\/_\-\.]+:\d+)              # File
                     \s+
                     \(([\w\_\-\d]+)\s*-\s*[\dxa-fA-F]+\) # Type
                     \s+
                     ([^\s]+)                          # Thread
                     \s+
                     (.+)                              # Msg
                     /x);
      if (!$dir) {$dir = '.'}
      if (!$pid) {$pid = "n/a"}
      $router = "n/a";
    }

    if (!$msg || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $user, $pid, $dir, $file, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                  # Date
                     (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+       # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*([\w\d\-_]+)   # Level
                     \s+
                     ([\w\d\-_]+)                      # User
                     \[(\d+)\]:?                       # PID
                     \s+
                     ([\w\d\/_\-\.]+)?                  # Directory
                     \s+
                     ([\w\d\/_\-\.]+:\d+)              # File
                     \s+
                     (.+)                              # Msg
                     /x);
        if (!$dir) {$dir = '.'}
        $thread = "n/a";
        $type = "n/a";
        $router = "n/a";
    }

    if (!$msg || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $user, $pid, $dir, $file, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                  # Date
                     (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+       # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*([\w\d\-_]+)   # Level
                     \s+
                     ([\w\d\-_]+):                     # User
                     .*\[(\d+)\]:?                     # PID
                     \s+
                     ([\w\d\/_\-\.]+)                  # Directory
                     \/
                     ([\w\d\/_\-\.]+:\d+)              # File
                     \s+
                     (.+)                              # Msg
                     /x);
        $thread = "n/a";
        $type = "n/a";
        $router = "n/a";
    }
    if (!$msg || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $user, $dir, $file, $type, $thread, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                    # Date
                     (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+       # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*([\w\d\-_]+)   # Level
                     \s+
                     ([\w\d\-_]+):                     # User
                     \s+
                     ([\w\d\/_\-\.]+)                  # Directory
                     \s+
                     ([\w\d\/_\-\.]+:\d+)              # File
                     \s+
                     \(([\w\_\-\d]+)\s*-\s*[\dxa-fA-F]+\) # Type
                     \s+
                     ([^\s]+)                          # Thread
                     \s+
                     (.+)                              # Msg
                     /x);
        $pid = 0;
        $router = "n/a";
    }
    if (!$msg || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $user, $pid, $dir, $file, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                  # Date
                      (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+      # Time
                      \s+
                      <[\w\d]+\.(\w+)>\s*              # Level
                      ([\w\d\-_]+)                     # Router
                      \s+
                      ([\w\d\-_\.]+)                      # User
                      \[(\d+)\]:?                       # PID
                      \s+
                      ([\w\d\/_\-\.]+)?                  # Directory
                      \s*
                      :?
                      ([\w\d\/_\-\.]+:\d+)              # File
                      \s+
                      (.+)                              # Msg
                      /x);
        $type = "";
        $thread = "";
    }
    if (!$msg || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $user, $pid, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                    # Date
                     (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+       # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*               # Level
                     ([\w\d\-_]+)                      # Router
                     \s+
                     ([\w\d\-_\.]+)                      # User
                      \[(\d+)\]:?                       # PID
                     \s+
                     (.*)                              # Msg
                     /x);
        $pid = 0;
        $dir = "";
        $file = "";
        $type = "";
        $thread = "";
    }
    # print "$line\n";
   #The reload logs changed their format.  Note this also matches a blank line

    if (!$msg || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $user, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                    # Date
                     (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+       # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*               # Level
                     ([\w\d\-_]+)                      # Router
                     \s+
                     ([\w\d\-_\.]+):?                  # User
                     \s+
                     (.*)                               #msg
                     /x);
        $pid = 0;
        $dir = "";
        $file = "";
        $type = "";
        $thread = "";
    }
    if (!$level || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $file, $pid, $user, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                    # Date
                     (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+       # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*               # Level
                     ([\w\d\-_]+)\s+                   # Router
                     ([\w\d\-_]+):?                      # Exec
                     \s*
                     .*\[(\d+)\]:?                     # PID
                     [\s:]+
                     ([\w\d\-_\.]+)                      # User
                     [\s:]+
                     (.+)                              # Msg
                     /x);
        $pid = 0;
    }

    if (!$msg || $msg =~ /^\s*$/) {
        ($date, $time, $level, $router, $file, $pid, $user, $msg) =
            ($line =~ /(\d+-\d+-\d+)T                    # Date
                     (\d+:\d+:\d+\.?\d{0,6})[\+\-][\d:]+       # Time
                     \s+
                     <[\w\d]+\.(\w+)>\s*               # Level
                     ([\w\d\-_]+)\s+                   # Router
                     .*\[(\d+)\]:?                     # PID
                     (.+)                              # Msg
                     /x);
        $pid = 0;
        $file = "";
        $user = "";
    }
    
    if (!$msg || $msg =~ /^\s*$/) {
      ($date, $time, $router, $user, $pid, $dir, $file, $type, $thread, $msg) = 
          ($line =~ /([A-Z][a-z]+\s\d+)\s+              # Date
                   (\d+:\d+:\d+)                     # Time
                   \s+
                   ([\w\d\-_]+)                      # Router
                   \s+
                   ([\w\d\-_]+)                      # User
                   \[(\d+)\]:?                       # PID
                   \s+
                   ([\w\d\/_\-\.]+)?                 # Directory
                   \s+
                   ([\w\d\/_\-\.]+:\d+)              # File
                   \s+
                   \(([\w\_\-\d]+)\s*-\s*[\dxa-fA-F]+\) # Type
                   \s+
                   ([^\s]+)                          # Thread
                   \s+
                   (.+)                              # Msg
                   /x);
      if (!$dir) {$dir = '.'}
      $router = "n/a";
    }

    if (!$msg || $msg =~ /^\s*$/) {
        my $errmsg = Dumper($line);
        print "Failed to parse: $errmsg\n" unless $noWarn;
        ($date, $time, $level, $router, $user, $pid, $dir, $file, $type, $thread, $msg) = ("", "", "", "", "", "", "", "", "", "", "");
    }

    # print "$date, $time, $level, $router, $user, $pid, $dir, $file, $type, $thread, $msg\n";
    # print "$line\n";
    return ($date, $time, $level, $router, $user, $pid, $dir, $file, $type, $thread, $msg);
}

##############################################################################
## StoreFields -
##
## Put all the parsed fields into a datastructure so that we can access them
## later
##
##############################################################################
sub StoreFields {
    my @values = @_;
    my @names = qw(date time level router user pid dir file type thread msg);
    my %record = ();

    foreach my $i (0 .. $#names) {
        $record{$names[$i]} = $values[$i];
        print "i: $i, name: $names[$i], value: $values[$i]\n";
    }

    return \%record;
} # StoreFields #

##############################################################################
## cleanMsg -
##
## Strip out simple variable things from the logs; homogenize numbers,
## look for SQL special characters, and so on.
##############################################################################
sub cleanMsg {
    my $msg = shift;
    #Some log messages have ' or ; in them, which hoses up the sql parser.
    #http://xkcd.com/327/
    $msg =~ s/[';]//g;
    die "NOTCLEAN: $msg\n" if ($msg =~ /;/);

    #Some log messages have rolling hex pointers which
    #make otherwise identical strings different.  If that
    #information is important to you, it is stored on the
    #router and in thesyslog archives.
    $msg =~ s/0x([0-9a-fA-F])+/0xdeaddead/g;

    $msg =~ s/( [0-9a-fA-F][0-9a-fA-F](?= ))+/ nn/g;
    $msg =~ s/ [0-9a-fA-F][0-9a-fA-F]&/ nn/g;

    #Any kind of ID number, we don't care about
    $msg =~ s/([iI]d)=(\S)+/$1=n/g;

    #Look for a filename:linenumber pattern, and turn the numbers into the letter n
    if ($msg =~ /\(\w+.\w+:\d+->\w+\)/) {
        my @peices = split(/\)/,$msg);
        $peices[1] =~ s/[\d\.]+/n/g;
        $msg = $peices[0] . ')' . $peices[1];
    } else {
        #Turn an integer or decmial number into n
        $msg =~ s/\d\.?\d+/n/g;
        $msg =~ s/\d/n/g;
        $msg =~ s/n, //g;
    }
    return $msg;
}


1;
