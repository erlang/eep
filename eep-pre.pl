#! /usr/bin/perl
##
## Preprocess EEP to correct links to self and index.
## Markdown preprocessor.
##
## Copyright 2010: Erlang/OTP, Raimo Niskanen
## This document has been placed in the public domain.
#

#
# Process <>
#
# Rewrite these Markdown constructs:
#
# [EEP n]: eep-NNNN.md   =>  [EEP n]: eep-NNNN.html
#
# [EEP]: ./              =>  [EEP]: eep-0000.html
#
# ****
# EEP N: Title
# ----
#                        =>
# ****
# [EEP](eep-0000.html "EEP Index") N: [Title](eep-NNNN.md "EEP Source")
# ----
#

require 5.008_000;
use strict;
use warnings;

my ($p, $pp);
$\ = "\n";

while (<>) {
    chomp;
    #
    s{^(\[ EEP \s+ \d+ \] : \s+ eep- \d+) \. md (?= \s*)}|$1.html|x; # EEP link
    s{^(\[ EEP \] : \s+) \./ (?= \s*)}|${1}eep-0000.html|x; # Index link
    if ($_ =~ m{\s* - \s* - \s* - [-\s]*|}
	&& defined $pp && $pp =~ m{\s* \* \s* \* \s* \* [\s\*]*}x
	&& $p =~ m{^EEP \s+ (\d+) : (.*)}x) # EEP *: Title
    {
	my ($num, $title) = ($1, $2);
	$title =~ s|([\[\]\(\)\"])|\\$1|g;
	$p = sprintf '[EEP](eep-0000.html "EEP Index") %d: '
	    .'[%s](eep-%04d.md "EEP Source")', $num, $title, $num;
    }
} continue {
    if (defined $pp) {
	print $pp or die "can't print: $!\n";
    }
    $pp = $p;
    $p = $_;
}
if (defined $pp) {
    print $pp or die "can't print: $!\n";
}
print $p or die "can't print: $!\n";
