#!/bin/env perl
#-*-perl-*-

use strict;
use DB_File;
use vars qw($opt_s $opt_t $opt_d);
use Getopt::Std;

getopts('d:s:t:');

my $SentAlignFile = shift(@ARGV);
my $WordAlignFile = shift(@ARGV);

my $srclang = $opt_s;
my $trglang = $opt_t;

open S,"gzip -cd <$SentAlignFile |" || die "cannot read from $SentAlignFile";
open W,"gzip -cd <$WordAlignFile |" || die "cannot read from $WordAlignFile";

my %alg = ();
my $first = 1;

while (<S>){
    chomp;
    my ($sdoc,$tdoc,$sids,$tids) = split(/\t/);

    # set source and target language if not set
    # (use first element in file path)
    unless ($srclang){
	$srclang = $sdoc;
	$srclang =~s/^([^\/]+)\/.*$/$1/;
    }
    unless ($trglang){
	$trglang = $tdoc;
	$trglang =~s/^([^\/]+)\/.*$/$1/;
    }

    ## open DB after the first entry
    ## (need to check srclang and trglang first)
    if ($first){
	my $DBFile = $opt_d || "$srclang-$trglang.db";
	tie %alg, 'DB_File', $DBFile;
	$first = 0;
    }

    my @src = split(/\s+/,$sids);
    my @trg = split(/\s+/,$tids);

    my $walign = <W>;
    chomp $walign;

    foreach my $s (@src){
	my $a = join("\t",$tdoc,$sids,$tids,$walign);
	$alg{"$sdoc:$s"} = $a;
    }
    # reverse alignment
    foreach my $t (@trg){
	my @alg = split(/\s+/,$walign);
	my @reverse = ();
	foreach (@alg){
	    my ($x,$y) = split(/\-/);
	    push (@reverse,"$y-$x");
	}
	$walign = join(' ',@reverse);
	my $a = join("\t",$sdoc,$tids,$sids,$walign);
	$alg{"$tdoc:$t"} = $a;
    }
}

$alg{"__srclang__"} = $srclang;
$alg{"__trglang__"} = $trglang;
