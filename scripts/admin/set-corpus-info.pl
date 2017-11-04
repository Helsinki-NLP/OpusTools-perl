#!/usr/bin/perl
#
# add info about a new bitext
#
# USAGE: set_corpus_info.pl corpus src-lang trglang


use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use OPUS::Tools;

my ($corpus,$src,$trg) = @ARGV;

die "specify corpus src trg" 
    unless (defined $corpus && defined $src && defined $trg);

set_corpus_info($corpus,$src,$trg);
