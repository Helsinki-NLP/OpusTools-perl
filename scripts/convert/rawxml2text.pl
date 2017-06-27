#!/usr/bin/perl
#

use XML::Parser;


my $XmlParser;
my $XmlHandler;

binmode(STDIN);
binmode(STDOUT, ":utf8");

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
	# warn $@;
	print STDERR $_;
	die $@;
    }
}


sub XmlTagStart{
    my ($p,$e,%a)=@_;
    if ($e eq 's'){
	$p->{SENT} = '';
    }
}

sub XmlChar{
    my ($p,$c)=@_;
    if (exists $p->{SENT}){
	$p->{SENT}.=$c;
    }
}

sub XmlTagEnd{
    my ($p,$e)=@_;
    if ($e eq 's'){
	$p->{SENT}=~s/\s+/ /gs;
	print $p->{SENT},"\n" if ($p->{SENT});
    }
}
