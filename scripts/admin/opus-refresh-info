#!/usr/bin/perl
#
# refresh corpus info for a given corpus
#
# USAGE: refresh_corpus_info.pl corpus


use strict;

use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use OPUS::Tools;

my ($corpus) = @ARGV;

die "specify corpus" unless (defined $corpus);

my @bitexts = glob("$OPUS_DOWNLOAD/$corpus/*.xml.gz");
my %done = ();

foreach my $b (@bitexts){
    $b = basename($b);
    if ($b=~/^([a-z\_]+)-([a-z\_]+).xml.gz/){
	my ($src,$trg) = ($1,$2);
	unless ($done{"$src-$trg"}){
	    print STDERR "set info for $corpus $src-$trg\n";
	    set_corpus_info($corpus,$src,$trg);
	    $done{"$src-$trg"} = 1;
	}
    }
}
