#!/bin/env perl
#-*-perl-*-

use strict;
use DB_File;
use vars qw($opt_d $opt_s);
use Getopt::Std;

getopts('d:s:');

my $docDB = $opt_d || 'docid.db';
my $sentDB = $opt_s || 'sentid.db';

my %docIDs = ();
my %sentIDs = ();

tie %docIDs, 'DB_File', $docDB;
tie %sentIDs, 'DB_File', $sentDB;


my $doc = undef;
my $sent = undef;

my $docid = 1;
my $sentid = 1;
my $wordid = 1;

my $tokenNr=0;

while (<>){
    my ($d,$t) = split(/\:/);
    if ($d ne $doc){
	if ($sent){
	    $sentIDs{"$docid:$sent"} .= "\t".$tokenNr;
	}
	if ($doc){
	    $docIDs{$doc} = $docid;
	    $docid++;
	}
	$doc = $d;
	$tokenNr = 0;
    }
    if ($t=~/<s\s+[^>]*id\=\"([^\"]+)\"/){
	if ($sent){
	    $sentIDs{"$docid:$sent"} .= "\t".$tokenNr;
	}
	$sent = $1;
	$sentIDs{"$docid:$sent"} = "$sentid\t$wordid";
	$sentid++;
	$tokenNr = 0;
    }
    elsif ($t=~/<w\s+/){
	$tokenNr++;
	$wordid++;
    }
}

if ($doc and $docid){
    $docIDs{$doc} = $docid;
}
if ($sent and $docid){
    $sentIDs{"$docid:$sent"} .= "\t".$tokenNr;
}
