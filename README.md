# pmdl

perl MySQL data loader that will automatically retry on DEADLOCK errors.

This script reads SQL instructions from the standard input separated by
a semicolon and newline and sends them to a MySQL server.  If the server
returns a DEADLOCK error, this script will attempt to send the SQL instruction
again until it commits sucessfully.

The trailing semicolon will be removed before the command is sent to the
server.

Lines beginning with '--' will be ignored. 

Usage: ../pmdl/pmdl.pl [dsn] [username] {password}
