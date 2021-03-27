package Solace::Expect::Generic;

use strict;
use warnings;
use Data::Dumper;
use Expect;
use Carp;

##
## Some generic routines for the other solace expect modules
##




##############################################################################
## spawnLocalShell - This will start a bash shell on the current router 
##
##############################################################################
sub spawnLocalShell {
  my ($objPtr, $debug) = @_;

  $$objPtr = new Expect();

  $$objPtr->raw_pty(1);
  $$objPtr->spawn("/bin/bash")
    or die("Cannot spawn \"/bin/bash\": $!\n");
  
  if ($debug) {
    $$objPtr->log_stdout(1);
  }
  else {
    $$objPtr->log_stdout(0);
  }

  my $match = $$objPtr->expect(10, '# ', "\n% ", "RRS>: ");
  if (!defined $match) {
    print "Couldn't start local shell on router\n" if $debug;
    return undef;
  }

  return 0;

} # spawnLocalShell #



##############################################################################
## spawnSimulator - This will start the specified process locally 
##
##############################################################################
sub spawnSimulator {
  my ($objPtr, $debug, $successPrompt, $cmd) = @_;

  $$objPtr = new Expect();

  $$objPtr->raw_pty(1);
  $$objPtr->spawn("$cmd") or die("Cannot spawn \"$cmd\": $!\n");
  
  if ($debug) {
    $$objPtr->log_stdout(1);
  }
  else {
    $$objPtr->log_stdout(0);
  }

  my $match = $$objPtr->expect(10, $successPrompt);
  if (!defined $match) {
    print "Couldn't start command: $cmd\n" if $debug;
    return undef;
  }

  return 0;

} # spawnSimulator #



##############################################################################
## spawnSshAndLogin - 
##
## This will start and expect session and connect to the router. 
##
##############################################################################
sub spawnSshAndLogin {
  my ($loginLocation, $password, $objPtr, $debug, $successPrompt) = @_;

  my @ports = (2222, 22);
  my $msg = "";
  
  while (my $port = shift(@ports)) {
    
    $$objPtr = new Expect();

    $$objPtr->raw_pty(1);
    $$objPtr->spawn("ssh", $loginLocation,
                    "-p $port",
                    "-oUserKnownHostsFile=/dev/null ",
                    "-oStrictHostKeyChecking=no ")
        or die("Cannot spawn \"ssh $loginLocation\": $!\n");

    if ($debug) {
      $$objPtr->log_stdout(1);
    }
    else {
      $$objPtr->log_stdout(0);
    }

    my $match = $$objPtr->expect(10,
                                 [ "assword: " => 
                                   sub {
                                     $$objPtr->send("$password\r");
                                     exp_continue;
                                   }, 
                                   "continue connecting (yes/no)? " => 
                                   sub { 
                                     $$objPtr->send("yes\r");
                                     exp_continue;
                                   }
                                 ],
                                 $successPrompt,
                                 "Please try again later...",
                                 "Dropping to shell..."
        );
    my $result = $$objPtr->before();

    if (!defined $match) {
      $msg = "Couldn't log into router with $loginLocation\n";
      next;
    }

    if ($match == 3 || $match == 4) {
      print "Router S/W is not ready yet.  Please try again later.\n" if $debug;
      return undef;
    }

    return 0;
    
  }

  print $msg if $debug;

  return undef;

} # spawnSshAndLogin #


##############################################################################
## spawnLabConsoleAndLogin - 
##
## This will start and expect session and connect to the router using the 
## lab-console script
##
##############################################################################
sub spawnLabConsoleAndLogin {
  my ($loginLocation, $user, $password, $objPtr, $debug, $successPrompt, $kill) = @_;

  $$objPtr = new Expect();

  $$objPtr->raw_pty(1);
  my @params = ("/usr/local/devtools/bin/lab-console", 
                "--quiet",
                "$loginLocation");
  push(@params, "--kill") if $kill;
  $$objPtr->spawn(@params) or die("Cannot spawn \"lab-console $loginLocation\": $!\n");

  if ($debug) {
    $$objPtr->log_stdout(1);
  }
  else {
    $$objPtr->log_stdout(0);
  }

  my $match = $$objPtr->expect(10, "Escape character");

  if (!defined($match) || $match != 1) {
    carp("Something doesn't look right with the terminal server. Will try to continue...");
    sleep(2);
  }

  # Send some ^Ds and enters to try to get back to the login prompt
  $$objPtr->send("\n");

  my $attempts = 4;

  while ($attempts--) {
    # print "Attempts left $attempts\n";
    $match = $$objPtr->expect(4,
                        [ 
                          "RRS>:" => 
                          sub {
                            $$objPtr->send("exit\r");
                            exp_continue;
                          }, 
                        ],
                        [ 
                          qr/\](\$|\#)/ => 
                          sub {
                            $$objPtr->send("exit\r");
                            exp_continue;
                          }, 
                        ],
                        [ 
                          qr/^[\d\-_\(\)\w\/\.]*(#|>) / => 
                          sub {
                            $$objPtr->send("exit\r");
                            exp_continue;
                          }, 
                        ],
                        [ 
                          "continue connecting (yes/no)? " => 
                          sub { 
                            $$objPtr->send("yes\r");
                            exp_continue;
                          }
                        ],
                        "ogin:"
      );
    if (defined $match) {
      last;
    }
    # Sometimes we have to kick it with a few newlines
    $$objPtr->send("\n\r");
  }

  if (!defined $match) {
    print "Couldn't log into router with $loginLocation. No login prompt\n" if $debug;
    return undef;
  }

  $$objPtr->send("\r");
  
  $attempts = 3;
  $match = $$objPtr->expect(10,
                        [ 
                          qr/last login:/i => 
                          sub {
                            exp_continue;
                          }, 
                        ],
                        [ 
                          qr/login:/i => 
                          sub {
                            if ($attempts--) {
                              $$objPtr->send("$user\r");
                              exp_continue;
                            }
                          }, 
                        ],
                        [ 
                          "assword:" => 
                          sub {
                            $$objPtr->send("$password\r");
                            exp_continue;
                          }, 
                        ],
                        [ 
                          "continue connecting (yes/no)? " => 
                          sub { 
                            $$objPtr->send("yes\r");
                            exp_continue;
                          }
                        ],
                        $successPrompt,
                        "Please try again later...",
                        "Dropping to shell..."
      );

  my $result = $$objPtr->before();

  $$objPtr->send("stty -echo\r");
  $$objPtr->expect(10, $successPrompt);

  if (!defined $match) {
    print "Couldn't log into router with $loginLocation\n" if $debug;
    return undef;
  }

  if ($match == 1 || $match == 6 || $match == 7) {
    print "Router S/W is not ready yet.  Please try again later.\n" if $debug;
    return undef
  }

  return 0;

} # spawnLabConsoleAndLogin #


##############################################################################
## spawnSshWithKeyfile -
##
## This will start and expect session and connect to the router using an
## SSH keyfile.
##
##############################################################################
sub spawnSshWithKeyfile {
  my ($loginLocation, $keyfile, $objPtr, $debug, $successPrompt) = @_;

  my @ports = (2222, 22);
  my $msg;
  
  while (my $port = shift(@ports)) {

    $$objPtr = new Expect();
    $$objPtr->raw_pty(1);
    $$objPtr->spawn("ssh", 
                    "-p $port",
                    "-i","$keyfile","$loginLocation")
        or die("Cannot spawn \"ssh -i $keyfile $loginLocation\": $!\n");

    if ($debug) {
      $$objPtr->log_stdout(1);
    }
    else {
      $$objPtr->log_stdout(0);
    }

    my $match = $$objPtr->expect(10, 
                                 "assword: ", 
                                 $successPrompt,
                                 "Please try again later...",
                                 "continue connecting (yes/no)? ");
    my $result = $$objPtr->before();

    if (!defined $match) {
      $msg = "Couldn't log into router with $loginLocation\n";
      next;
    }


    # SSH unknown host
    if ($match == 4) {
      $$objPtr->send("yes\r");
      $match = $$objPtr->expect(10, 
                                "assword: ", 
                                $successPrompt,
                                "Please try again later..."
          );
    }

    if (!defined $match) {
      $msg = "Couldn't log into router $loginLocation with keyfile $keyfile\n";
      next;
    }

    if (!defined $match || $match == 4 || $match == 1) {
      $$objPtr->hard_close();
      next;
    }
    
    if ($match == 3) {
      print "Router S/W is not ready yet.  Please try again later.\n" if $debug;
      return undef;
    }

    return 0;

  }

  print $msg if $debug;
  return undef;

} # spawnSshWithKeyfile #


##############################################################################
## spawnSftpWithKeyfile -
##
## This will start an SFTP expect session and connect to the router using an
## SSH keyfile.
##
##############################################################################
sub spawnSftpWithKeyfile {
  my ($loginLocation, $keyfile, $objPtr, $debug, $successPrompt) = @_;

  $$objPtr = new Expect();

  $$objPtr->raw_pty(1);
  $$objPtr->spawn("sftp", ("-oIdentityFile","$keyfile","$loginLocation"))
      or die("Cannot spawn \"sftp -oIdentityFile $keyfile $loginLocation\": $!\n");

  if ($debug) {
    $$objPtr->log_stdout(1);
  }
  else {
    $$objPtr->log_stdout(0);
  }

  my $match = $$objPtr->expect(10, 
                           "assword: ", 
                           $successPrompt,
                           "Please try again later...",
                           "continue connecting (yes/no)? ");
  my $result = $$objPtr->before();

  if (!defined $match) {
    print "Couldn't log into router with $loginLocation\n" if $debug;
    return undef;
  }


  # SFTP unknown host
  if ($match == 4) {
    $$objPtr->send("yes\r");
    $match = $$objPtr->expect(10, 
                          "assword: ", 
                          $successPrompt,
                          "Please try again later..."
        );
  }

  if (!defined $match) {
    print "Couldn't log into router $loginLocation with keyfile $keyfile\n" if $debug;
    return undef;
  }

  if (!defined $match || $match == 4 || $match == 1) {
    $$objPtr->hard_close();
    return undef;
  }
  
  if ($match == 3) {
    print "Router S/W is not ready yet.  Please try again later.\n" if $debug;
    return undef
  }

  return 0;

} # spawnSftpWithKeyfile #


##############################################################################
## spawnSftpAndLogin -
##
## This will start an SFTP expect session and connect to the router.
##
##############################################################################
sub spawnSftpAndLogin {
  my ($loginLocation, $password, $objPtr, $debug, $successPrompt) = @_;

  $$objPtr = new Expect();

  $$objPtr->raw_pty(1);
  $$objPtr->spawn("sftp", $loginLocation)
      or die("Cannot spawn \"sftp $loginLocation\": $!\n");

  if ($debug) {
    $$objPtr->log_stdout(1);
  }
  else {
    $$objPtr->log_stdout(0);
  }
  #$$objPtr->debug(3);
  #$$objPtr->exp_internal(1);

  my $match = $$objPtr->expect(10,
                           "assword: ",
                           $successPrompt,
                           "Please try again later...",
                           "continue connecting (yes/no)? ");
  my $result = $$objPtr->before();

  if (!defined $match) {
    print "Couldn't log into router with $loginLocation\n" if $debug;
    return undef;
  }


  # SFTP unknown host
  if ($match == 4) {
    $$objPtr->send("yes\r");
    $match = $$objPtr->expect(10,
                          "assword: ",
                          $successPrompt,
                          "Please try again later..."
        );
  }

  if (!defined $match) {
    print "Couldn't log into router with $loginLocation\n" if $debug;
    return undef;
  }

  # Deal with the password - assuming it asked for one
  if ($match == 1) {
    $$objPtr->send("$password\r");
    $match = $$objPtr->expect(10,
                          $successPrompt,
                          "NEVER MATCH THIS",
                          "Please try again later...",
                          "assword: ");
  }

  if (!defined $match || $match == 4) {
    $$objPtr->hard_close();
    return undef;
  }
  
  if ($match == 3) {
    print "Router S/W is not ready yet.  Please try again later.\n" if $debug;
    return undef
  }

  return 0;

} # spawnSftpAndLogin #


1;
