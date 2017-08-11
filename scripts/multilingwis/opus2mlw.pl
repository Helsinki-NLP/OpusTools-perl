#!/bin/env perl
#-*-perl-*-

use strict;
use vars qw($opt_d);
use Getopt::Std;
use File::Basename;
use XML::Parser;
use DB_File;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

getopts('d:');

my $CorpusDir = $opt_d || '../parsed';

my $DocIdFile  = shift(@ARGV);
my $SentIdFile = shift(@ARGV);
my $WordIdFile = shift(@ARGV);

# open all alignment DBs
my @alg = ();
foreach (0..$#ARGV){
    %{$alg[$_]} = ();
    tie %{$alg[$_]},  'DB_File', $ARGV[$_];
}
my @dblang = ();
foreach my $db (@alg){
    push(@dblang,$$db{__srclang__});
}

# read file with unique doc ids
my %docid=();
open F,"<$DocIdFile" || die "cannot open $DocIdFile";
while (<F>){
    chomp;
    my ($id,$file) = split(/\t/);
    $docid{$file} = $id;
}
close F;

# read file with unique word ids
my @wordid=();
open F,"<$WordIdFile" || die "cannot open $WordIdFile";
while (<F>){
    chomp;
    my ($id,$file,$sid) = split(/\t/);
    next if (not exists $docid{$file});
    my $doc = $docid{$file};
    $wordid[$doc]{$sid} = $id;
}
close F;


my $current = undef;
my @sentences = ();
my %sentids = ();
my %done = ();
my $did;
my $lang;

open S,"<$SentIdFile" || die "cannot open $SentIdFile";
while (<S>){
    chomp;
    my ($id,$doc,$sid) = split(/\t/);
    next if (not exists $docid{$doc});

    if ($doc ne $current){
	PrintSentences($current,\@sentences) if ($current);
	@sentences = ();
	ReadDocument($doc,\@sentences);
	foreach my $s (0..$#sentences){
	    $sentids{$sentences[$s][0][9]} = $s;
	}
	$current = $doc;
	$did = $docid{$doc};
	$lang = $doc;
	$lang =~s/^([^\/]+)\/.*$/$1/;
	if ($lang eq 'sv'){
	    print '';
	}
    }

    foreach my $db (@alg){
	if ($lang ne $$db{__srclang__}){
	    next if ($lang ne $$db{__trglang__});
	}
	my ($tdoc,$sids,$tids,$walign) = split(/\t/,$$db{"$doc:$sid"});
	AddAlignment($sentences[$sentids{$sid}],$tdoc,$tids,$walign);
    }
    foreach my $w (0..$#{$sentences[$sentids{$sid}]}){
	$sentences[$sentids{$sid}][$w][9] = $id;       # set global sid
    }
}

PrintSentences($current,\@sentences) if ($current);




sub PrintSentences{
    my ($doc,$sent) = @_;
    my $did = $docid{$doc};
    my $lang = $doc;
    $lang =~s/^([^\/]+)\/.*$/$1/;
    foreach my $s (@{$sent}){
	my $sid = $$s[0][9];
	next if ($done{"$did:$sid"});

	## replace head with global token ID
	foreach my $w (0..$#{$s}){
	    my $head = $$s[$w][6];
	    if ($head > 0){
		my $headid = $wordid[$did]{$$s[$head-1][8]};
		$$s[$w][6] = $headid;
	    }
	}

	## set global IDs (token, sentence, doc)
	foreach my $w (0..$#{$s}){
	    my $wid = $wordid[$did]{$$s[$w][8]};
	    if ($done{$wid}){
		print STDERR "Word $wid already done?! (skip sentence $sid)\n";
		next;
	    }
	    $done{$wid}++;
	    $$s[$w][8] = $wid;
	    $$s[$w][9] = $sid;
	    $$s[$w][10] = $did;
	    $$s[$w][11] = '1' unless (defined $$s[$w][11]);
	    $$s[$w][12] = $lang;
	    $$s[$w][13] = '0' unless ($$s[$w][13]);  ## TODO: is that OK?
	    $$s[$w][14] = '{}';
	    print join("\t",@{$$s[$w]});
	    print "\n";
	}
	$done{"$did:$sid"}++;
#	print "\n";
    }
}



sub AddAlignment{
    my ($sentence,$docalign,$sentalign,$wordalign) = @_;

    my $did = $docid{$docalign};
    my @sentaligns = split(/\s+/,$sentalign);
    my @wordaligns = split(/\s+/,$wordalign);

    my %links = ();
    foreach my $a (@wordaligns){
	my ($s,$t) = split(/\-/,$a);
	$links{$s}{$t} = 1;
    }

    ## get all word IDs for all aligned sentences
    ## NOTE: assume that we have regular IDs that correspond
    ##       to sentence IDs ---> DANGEROUS!
    
    my @wids = ();
    foreach (@sentaligns){
	my $id = $_;
	$id =~s/^s/w/;
	my $wnr = 1;
	while (exists $wordid[$did]{"$id.$wnr"}){
	    push(@wids,"$id.$wnr");
	    $wnr++;
	}
    }

    ## run through all words in the current sentence
    foreach my $w (0..$#{$sentence}){
	unless (exists $links{$w}){
	    $$sentence[$w][13] = '0';     ## TODO: is that OK?
	    next;
	}
	my @links = ();
	foreach my $l (sort {$a <=> $b} keys %{$links{$w}}){
	    if ($wordid[$did]{$wids[$l]}){
		push(@links,$wordid[$did]{$wids[$l]});
	    }
	    else{
		print STDERR "no id found for token $l ($wids[$l]) in doc $docalign sent $$sentence[$w][9]\n";
	    }
	}
	if (@links){
	    if ($$sentence[$w][13]){
		$$sentence[$w][13] .= '|'.join('|',@links);
	    }
	    else{
		$$sentence[$w][13] = join('|',@links);
	    }
	}
    }
}




sub AddAlignmentOLD{
    my ($sdocid,$tdocid,$sent,$alg,$reverse) = @_;
    foreach my $s (@{$sent}){
	my $sid = $$s[0][9];
	next unless (exists $$alg{$sid});
	
	## get all word alignments
	my @alg = split(/\s+/,$$alg{$sid}[2]);
	my %links = ();
	foreach my $a (@alg){
	    my ($sl,$tl) = split(/\-/,$a);
	    ($sl,$tl) = ($tl,$sl) if ($reverse);
	    $links{$sl}{$tl} = 1;
	}

	## get all word IDs for all aligned sentences
	## NOTE: assume that we have regular IDs that correspond
	##       to sentence IDs ---> DANGEROUS!

	my @tids = split(/\s+/,$$alg{$sid}[1]);
	if ($#tids){
	    print '';
	}
	my @wids = ();
	foreach (@tids){
	    my $id = $_;
	    $id =~s/^s/w/;
	    my $wnr = 1;
	    while (exists $wordid[$tdocid]{"$id.$wnr"}){
		push(@wids,"$id.$wnr");
		$wnr++;
	    }
	}

	## run through all words in the current sentence
	foreach my $w (0..$#{$s}){
	    unless (exists $links{$w}){
		$$s[$w][13] = '0';         ## TODO: is that OK?
		next;
	    }
	    my @links = ();
	    foreach my $l (sort {$a <=> $b} keys %{$links{$w}}){
		if ($wordid[$tdocid]{$wids[$l]}){
		    push(@links,$wordid[$tdocid]{$wids[$l]});
		}
		else{
		    print STDERR "no id found for token $l ($wids[$l]) in doc $tdocid sent $$alg{$sid}[1]\n";
		}
	    }
	    $$s[$w][13] = join('|',@links);
	}
    }
}


sub ReadDocument{
    my ($doc,$sent) = @_;

    my $XmlParser = new XML::Parser(Handlers => {Start => \&XmlTagStart,
						 End => \&XmlTagEnd,
						 Default => \&XmlChar});
    my $XmlHandle = $XmlParser->parse_start;
    $XmlHandle->{SENT} = $sent;

    open F,"gzip -cd <$CorpusDir/$doc |" || die "cannot read from $doc";

    while (<F>){
    	eval { $XmlHandle->parse_more($_); };
    	if ($@){
    	    warn $@;
    	    print STDERR $_;
    	}
    }
    close F;
}

sub XmlTagStart{
    my ($p,$e,%a)=@_;
    if ($e eq 's'){
	$$p{SID} = $a{id};
	my $idx = @{$$p{SENT}};
	$$p{SENT}[$idx] = [];
	$$p{SPACE} = 0;
    }
    elsif ($e eq 'w'){
	my $idx = @{$$p{SENT}[-1]};
	$$p{SENT}[-1][$idx][0] = $idx+1;
	$$p{SENT}[-1][$idx][2] = $a{lemma};
	$$p{SENT}[-1][$idx][3] = $a{upos};
	$$p{SENT}[-1][$idx][4] = $a{xpos};
	$$p{SENT}[-1][$idx][5] = $a{feats} ? $a{feats} : '_';
	$$p{SENT}[-1][$idx][6] = $a{head};
	$$p{SENT}[-1][$idx][7] = $a{deprel};
	$$p{SENT}[-1][$idx][8] = $a{id};
	$$p{SENT}[-1][$idx][9] = $$p{SID};
	$$p{SENT}[-1][$idx][11] = $$p{SPACE};
	$$p{WID}{$a{id}} = $idx+1;
	$$p{OPENW} = 1;
	if ($a{misc}=~/SpaceAfter=No/){
	    $$p{SPACE} = 0;
	}
	else{
	    $$p{SPACE} = 1;
	}
    }
}

sub XmlChar{
    my ($p,$c)=@_;
    if ($$p{OPENW}){
	$$p{WORD}.=$c;
    }
}

sub XmlTagEnd{
    my ($p,$e)=@_;
    if ($e eq 'w'){
	$$p{WORD}=~s/^\s*//;
	$$p{WORD}=~s/\s*$//;
	$$p{SENT}[-1][-1][1] = $$p{WORD};
	$$p{WORD} = '';
	$$p{OPENW} = 0;
    }
    elsif ($e eq 's'){
     	foreach my $w (@{$$p{SENT}[-1]}){
     	    if ($$w[6]){
     		$$w[6] = $$p{WID}{$$w[6]};
     	    }
     	}
     	delete $$p{WID};
    }
}

