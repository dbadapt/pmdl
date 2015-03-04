#!/usr/bin/perl -w
use strict;

use DBI;
use Try::Tiny;

# david.bennett@percona.com - 2015-03-04 
# Thanks to Ross for a stackoverflow post that assisted in writing this

if ($#ARGV < 2) {
  print<<END_OF_USAGE;

This script reads SQL instructions from the standard input separated by
a semicolon and newline and sends them to a MySQL server.  If the server
returns a DEADLOCK error, this script will attempt to send the SQL instruction
again until it commits sucessfully.

The trailing semicolon will be removed before the command is sent to the
server.

Lines beginning with '--' will be ignored. 

Usage: $0 [dsn] [username] {password}

END_OF_USAGE
  exit;
}

# deadlock handler

sub dbi_err_handler
{
    my($message) = @_;
    my $retval=1;
    if($message=~ m/DEADLOCK/i)
    {
       $retval=0; # we'll check this value and sleep/re-execute if necessary
    }
    return $retval;
}

# main loop

my $dbh = DBI->connect($ARGV[0], $ARGV[1], $ARGV[2], {'RaiseError' => 1});

my $line=0;
my $cmd='';
while (<STDIN>) {
  $line++;

  # ignore comments
  if (m/^\s*--/) {
    next;
  }

  # append command
  $cmd .= $_;

  # check for end of line
  if (m/;\s*$/) {
    $cmd =~ s/;\s*$//sg;
    
    # issue the command to the server
    my $sth = $dbh->prepare($cmd);
    my $db_res=0;
    while($db_res==0) {
      $db_res=1;
      try {
        $sth->execute();
      } catch {
        print "$line: caught $_\n$cmd\n";
        $db_res=dbi_err_handler($_);
        if($db_res==0){sleep 3;}
      }
    }
    $sth->finish();
    # clear the command buffer
    $cmd='';
  }
}

$dbh->disconnect();
exit 0;

  
