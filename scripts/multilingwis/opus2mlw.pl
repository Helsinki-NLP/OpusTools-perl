#!/bin/env perl
#-*-perl-*-

use strict;
use warnings;

use vars qw($opt_d);
use Getopt::Std;
use File::Basename;
use XML::Parser;
use DB_File;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

getopts('d:');

my $CorpusDir  = $opt_d || '../parsed';
my $DocIdFile  = shift(@ARGV);
my $SentIdFile = shift(@ARGV);

my %docid = ();
my %sentid = ();
tie %docid,  'DB_File', $DocIdFile;
tie %sentid,  'DB_File', $SentIdFile;

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

my $current = '';
my @sentences = ();
my %sentids = ();
my %done = ();
my $did;
my $lang;


while (<STDIN>){
    if (/^(.*)\:\s*<s\s+[^>]*id\=\"([^\"]+)\"/){
	my ($doc,$sid) = ($1,$2);

	if ($doc ne $current){
	    print STDERR "processing $doc ...\n";
	    PrintSentences($did,$lang,\@sentences) if ($current);
	    @sentences = ();
	    ReadDocument($doc,\@sentences);
	    foreach my $s (0..$#sentences){
		$sentids{$sentences[$s][0][9]} = $s;
	    }
	    $current = $doc;
	    $did = $docid{$doc};
	    $lang = $doc;
	    $lang =~s/^([^\/]+)\/.*$/$1/;
	}

	foreach my $db (@alg){
	    if ($lang ne $$db{__srclang__}){
		next if ($lang ne $$db{__trglang__});
	    }
	    if (exists $$db{"$doc:$sid"}){
		my ($tdoc,$sids,$tids,$walign) = split(/\t/,$$db{"$doc:$sid"});
		if ($tdoc && $tids && $walign){
		    AddAlignment($sentences[$sentids{$sid}],$tdoc,$tids,$walign);
		}
	    }
#	    else{
#		print STDERR "no alignments found for $doc:$sid\n";
#	    }
	}
    }
}
PrintSentences($did,$lang,\@sentences) if ($current);



sub PrintSentences{
    my ($did,$lang,$sent) = @_;

    foreach my $s (@{$sent}){

	my $sid = $$s[0][9];
	my ($id,$wstart,$nr) = split(/\t/,$sentid{"$did:$sid"});

	next if ($done{"$did:$sid"});

	## replace head with global token ID
	## TODO: do we need to do that?
	foreach my $w (0..$#{$s}){
	    if ($$s[$w][6] > 0){
		$$s[$w][6] = $wstart + $$s[$w][6] - 1;
	    }
	}

	## set global IDs (token, sentence, doc)
	foreach my $w (0..$#{$s}){
	    my $wid = $wstart + $w;
	    if ($done{$wid}){
		print STDERR "Word $wid already done?! (skip sentence $sid)\n";
		next;
	    }
	    $done{$wid}++;
	    ## avoid single underscore
	    $$s[$w][1] = '__' if ($$s[$w][1] eq '_');
	    ## copy word form if no lemma is given
	    $$s[$w][2] = $$s[$w][1] unless ($$s[$w][2]);
	    $$s[$w][8] = $wid;
	    $$s[$w][9] = $id;
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
    
    my @wids = ();
    foreach my $sid (@sentaligns){
	next unless (exists $sentid{"$did:$sid"});
	my ($id,$w,$n) = split(/\t/,$sentid{"$did:$sid"});
	next unless ($n);
	foreach my $x (0..$n-1){
	    push(@wids,$w+$x);
	}
    }

    ## run through all words in the current sentence
    foreach my $w (0..$#{$sentence}){
	unless (exists $links{$w}){
	    $$sentence[$w][13] = '0';     ## TODO: is that OK?
	    next;
	}
	my @linked = ();
	foreach my $l (sort {$a <=> $b} keys %{$links{$w}}){
	    if ($l<=$#wids){
		push(@linked,$wids[$l]);
	    }
	}
	if (@linked){
	    if ($$sentence[$w][13]){
		$$sentence[$w][13] .= '|'.join('|',@linked);
	    }
	    else{
		$$sentence[$w][13] = join('|',@linked);
	    }
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
	$$p{SENT}[-1][$idx][3] = $a{upos} || '_';
	$$p{SENT}[-1][$idx][4] = $a{xpos} || '_';
	$$p{SENT}[-1][$idx][5] = $a{feats} ? $a{feats} : '_';
	$$p{SENT}[-1][$idx][6] = $a{head} || 0;
	$$p{SENT}[-1][$idx][7] = $a{deprel} || 'ROOT';
	$$p{SENT}[-1][$idx][8] = $a{id};
	$$p{SENT}[-1][$idx][9] = $$p{SID};
	$$p{SENT}[-1][$idx][11] = $$p{SPACE};
	$$p{WID}{$a{id}} = $idx+1;
	$$p{OPENW} = 1;
	if (exists $a{misc} && $a{misc}=~/SpaceAfter=No/){
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
	$$p{SENT}[-1][-1][1] = $$p{WORD} || 'EMPTY';
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

