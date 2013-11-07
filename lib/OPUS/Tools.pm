#-*-perl-*-
#---------------------------------------------------------------------------
# Copyright (C) 2004-2013 Joerg Tiedemann
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
opusread OPUS/corpus/RF/xml/en-fr.xml.gz | less

# convert an OPUS bitext to plain text (Moses) format
zcat OPUS/corpus/RF/xml/en-fr.xml.gz | \
opus2moses -d OPUS/corpus/RF/xml -e RF.en-fr.en -f RF.en-fr.fr

# create a multilingual corpus from the parallel RF corpus
# using 'en' as the pivot language
opus2multi OPUS/corpus/RF/xml sv de en es fr


=head1 DESCRIPTION

This is not a library but just a collection of scripts for processing/converting OPUS corpora.
Download corpus data in XML from L<http://opus.lingfil.uu.se>


=cut

package OPUS::Tools;

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
