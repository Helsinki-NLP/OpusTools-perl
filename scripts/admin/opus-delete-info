#!/usr/bin/perl
#
# delete all information of a specific corpus
# (this is hard-coded now)

my $corpus = "OpenSubtitles2011";


# my $dbdir = '/home/opus/OPUS/html';
my $dbdir = '.';

use strict;
use DB_File;

tie my %LangNames,"DB_File","$dbdir/LangNames.db";
tie my %Corpora,"DB_File","$dbdir/Corpora.db";
tie my %LangPairs,"DB_File","$dbdir/LangPairs.db";
tie my %Bitexts,"DB_File","$dbdir/Bitexts.db";
tie my %Info,"DB_File","$dbdir/Info.db";


foreach my $c (keys %Corpora){
    my @corpora = split(/\:/,$Corpora{$c});
    if (grep($_ eq $corpus,@corpora)){
	@corpora = grep($_ ne $corpus,@corpora);
	$Corpora{$c} = join(':',@corpora);
    }
}

my %src2trg=();

foreach my $c (keys %Bitexts){
    my @corpora = split(/\:/,$Bitexts{$c});
    if (grep($_ eq $corpus,@corpora)){
	@corpora = grep($_ ne $corpus,@corpora);
	if (@corpora){
	    $Bitexts{$c} = join(':',@corpora);
	    my ($s,$t) = split(/\-/,$c);
	    $src2trg{$s}{$t}++;
	    $src2trg{$t}{$s}++;
	}
	else{
	    delete $Bitexts{$c};
	}
    }
    else{
	my ($s,$t) = split(/\-/,$c);
	$src2trg{$s}{$t}++;
	$src2trg{$t}{$s}++;
    }
}

foreach my $l (keys %LangPairs){
    $LangPairs{$l}=join(':',sort keys %{$src2trg{$l}});
}


foreach my $i (keys %Info){
    my ($c,$l) = split(/\//,$i);
    if ($c eq $corpus){
	delete $Info{$i};
    }
}

