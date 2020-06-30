#!/usr/bin/perl
use warnings;

die "Usage: <script> multiFASTA outputFile \n" if (!@ARGV);

my $psl = $ARGV[0]; ##  multiFASTA  file name
my $output = $ARGV[1]; ## filtered file output

# my $command = "grep ". " '>' " . $psl . " >" . $output ; ## command to pass to system call
my $command = "grep ". " '>' " . $psl  . " | " . " sed " . "'s/>//'" . " - " . " >" . $output ; ## command to pass to system call
#print $command;
#print $command;
system ($command); ## grep command




