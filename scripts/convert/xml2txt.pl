#!/usr/bin/perl
#

use XML::Parser;


my $XmlParser;
my $XmlHandler;

binmode(STDIN);
binmode(STDOUT, ":utf8");

my $ErrorCount=0;

while (<>){
    ## new document!
    if (/<\?xml/){
	$XmlParser = new XML::Parser(Handlers => {Start => \&XmlTagStart,
						  End => \&XmlTagEnd,
						  Char => \&XmlChar});
	$XmlHandler = $XmlParser->parse_start;
    }
    eval { $XmlHandler->parse_more($_); };
    if ($@){
	$ErrorCount++;
#	warn $@;              # skip millions of warnings!
#	print STDERR $_;
    }
}

print STDIN "$ErrorCount errors found!" if ($ErrorCount);


sub XmlTagStart{
    my ($p,$e,%a)=@_;
    if ($e eq 'w'){
	$p->{WORD} = '';
    }
    elsif ($e eq 's'){
	@{$p->{WORDS}}=();
    }
}

sub XmlChar{
    my ($p,$c)=@_;
    if (exists $p->{WORD}){
	$p->{WORD}.=$c;
    }
}

sub XmlTagEnd{
    my ($p,$e)=@_;
    if ($e eq 'w'){
	push (@{$p->{WORDS}},$p->{WORD}) if (exists $p->{WORD});
	delete $p->{WORD};
    }
    elsif ($e eq 's'){
	if (@{$p->{WORDS}}){
	    print join(' ',@{$p->{WORDS}});
	    print "\n";
	}
    }
}
