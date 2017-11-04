#-*-perl-*-
#---------------------------------------------------------------------------
# Copyright (C) 2004-2017 Joerg Tiedemann
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#---------------------------------------------------------------------------

=head1 NAME

OPUS::Tools - a collection of tools for processing OPUS corpora

=head1 SYNOPSIS

# read bitexts (print aligned sentences to screen in readable format)
opus-read OPUS/corpus/RF/xml/en-fr.xml.gz | less

# convert an OPUS bitext to plain text (Moses) format
zcat OPUS/corpus/RF/xml/en-fr.xml.gz | opus2moses -d OPUS/corpus/RF/xml -e RF.en-fr.en -f RF.en-fr.fr

# create a multilingual corpus from the parallel RF corpus
# using 'en' as the pivot language
opus2multi OPUS/corpus/RF/xml sv de en es fr


=head1 DESCRIPTION

This is not a library but just a collection of scripts for processing/converting OPUS corpora.
Download corpus data in XML from L<http://opus.lingfil.uu.se>


=cut

package OPUS::Tools;

use strict;
use DB_File;
use Exporter 'import';

our @EXPORT = qw(set_corpus_info $OPUS_HOME $OPUS_CORPUS $OPUS_HTML $OPUS_DOWNLOAD);

our $OPUS_HOME     = '/proj/nlpl/data/OPUS';
our $OPUS_HTML     = $OPUS_HOME.'/html';
our $OPUS_PUBLIC   = $OPUS_HOME.'/public_html';
our $OPUS_CORPUS   = $OPUS_HOME.'/corpus';
our $OPUS_DOWNLOAD = $OPUS_HOME.'/download';
our $INFODB_HOME   = $OPUS_PUBLIC;

our $VERBOSE = 0;

## variables for info databases

my %LangNames;
my %Corpora;
my %LangPairs;
my %Bitexts;
my %Info;

my $DBOPEN = 0;


sub open_info_dbs{
    tie %LangNames,"DB_File","$INFODB_HOME/LangNames.db";
    tie %Corpora,"DB_File","$INFODB_HOME/Corpora.db";
    tie %LangPairs,"DB_File","$INFODB_HOME/LangPairs.db";
    tie %Bitexts,"DB_File","$INFODB_HOME/Bitexts.db";
    tie %Info,"DB_File","$INFODB_HOME/Info.db";
    $DBOPEN = 1;
}

sub close_info_dbs{
    untie %LangNames;
    untie %Corpora;
    untie %LangPairs;
    untie %Bitexts;
    untie %Info;
    $DBOPEN = 0;
}

sub set_corpus_info{
    my ($corpus,$src,$trg,$infostr) = @_;

    unless (defined $corpus && defined $src && defined $trg){
	print STDERR "specify corpus src trg";
	return 0;
    }

    &open_info_dbs unless ($DBOPEN);

    ## set corpus for source and target language
    foreach my $l ($src,$trg){
	if (exists $Corpora{$l}){
	    my @corpora = split(/\:/,$Corpora{$l});
	    unless (grep($_ eq $corpus,@corpora)){
		push(@corpora,$corpus);
		@corpora = sort @corpora;
		$Corpora{$l} = join(':',@corpora);
	    }
	}
	else{
	    $Corpora{$l} = $corpus;
	}
    }

    ## set corpus for bitext
    my $langpair = join('-',sort ($src,$trg));
    if (exists $Bitexts{$langpair}){
	my @corpora = split(/\:/,$Bitexts{$langpair});
	unless (grep($_ eq $corpus,@corpora)){
	    push(@corpora,$corpus);
	    @corpora = sort @corpora;
	    $Bitexts{$langpair} = join(':',@corpora);
	}
    }
    else{
	$Bitexts{$langpair} = $corpus;
    }


    ## set src-trg
    if (exists $LangPairs{$src}){
	my @lang = split(/\:/,$LangPairs{$src});
	unless (grep($_ eq $trg,@lang)){
	    push(@lang,$trg);
	    @lang = sort @lang;
	    $LangPairs{$src} = join(':',@lang);
	}
    }
    else{
	$LangPairs{$src} = $trg;
    }

    ## set trg-src
    if (exists $LangPairs{$trg}){
	my @lang = split(/\:/,$LangPairs{$trg});
	unless (grep($_ eq $src,@lang)){
	    push(@lang,$src);
	    @lang = sort @lang;
	    $LangPairs{$trg} = join(':',@lang);
	}
    }
    else{
	$LangPairs{$trg} = $src;
    }

    unless ($infostr){
	$infostr = read_info_files($corpus,$src,$trg);
    }

    my $key = $corpus.'/'.$langpair;
    if ($infostr){
	if ($VERBOSE){
	    if (exists $Info{$key}){
		my $info = $Info{$key};
		print STDERR "overwrite corpus info!\n";
		print STDERR "old = ",$Info{$key},"\n";
		print STDERR "new = ",$infostr,"\n";
	    }
	}
	$Info{$key} = $infostr;
    }
}


sub read_info_files{
    my ($corpus,$src,$trg) = @_;

    my $CorpusXML = $OPUS_HOME.'/corpus/'.$corpus.'/xml';
    my $langpair  = join('-',sort ($src,$trg));

    my $key = $corpus.'/'.$langpair;
    my $moses = 'moses='.$key.'.txt.zip';
    my $tmx = 'tmx='.$key.'.tmx.gz';
    my $xces = 'xces='.$key.'.xml.gz:';
    $xces .= $corpus.'/'.$src.'.tar.gz:';
    $xces .= $corpus.'/'.$trg.'.tar.gz';

    my @infos = ();

    if (-e "$CorpusXML/$langpair.txt.info"){
	open F, "<$CorpusXML/$langpair.txt.info";
	my @val = <F>;
	chomp(@val);
	$moses .= ':'.join(':',@val);
	push(@infos,$moses);
    }

    if (-e "$CorpusXML/$langpair.tmx.info"){
	open F, "<$CorpusXML/$langpair.tmx.info";
	my @val = <F>;
	chomp(@val);
	$tmx .= ':'.join(':',@val);
	push(@infos,$tmx);
    }

    if (-e "$CorpusXML/$langpair.info"){
	open F, "<$CorpusXML/$langpair.info";
	my @val = <F>;
	chomp(@val);
	$xces .= ':'.join(':',@val);
	push(@infos,$xces);
    }

    return join('+',@infos);
}





1;

__END__

=head1 AUTHOR

Joerg Tiedemann, L<https://bitbucket.org/tiedemann>

=head1 TODO

Better documentation in the individual scripts.

=head1 BUGS AND SUPPORT

Please report any bugs or feature requests to
L<https://bitbucket.org/tiedemann/opus-tools>.

=head1 SEE ALSO

L<http://opus.lingfil.uu.se>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Joerg Tiedemann.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
