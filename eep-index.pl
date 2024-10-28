#! /usr/bin/perl
##
## Scan headers of all EEPs and fill in the index
## in the tagged places. Preprocess Markdown.
##
## Copyright 2010: Erlang/OTP, Raimo Niskanen
## This document has been placed in the public domain.
#

#
# Argument: EEP_dir/Index_file.suffix
#
# Expand these markdown constructs into HTML tables on output:
#
# [Prefix] : <$me:>
# [Table Caption]: <$me:index/col1/col2...>
#

require 5.008_000;
use strict;
use warnings;

my $me = $0;
$me =~ s| .* / ||x;
$me =~ s| [.] .* $||x;

my $index = shift;
die "Missing argument: index file to fill in" unless defined $index;
$index =~ m|^ ((?:.* /)?) .*? ((?:[.] .*)*) $|x;
my $dir = $1;
my $suffix = $2;
my $lf = "\n";

my $type_suffix = ' EEP';
my $status_suffix = ' proposal';

my @type =
    ('Standards Track' => 'S',
     'Process' => 'P',
     );
my @status =
    ('Active' => '',
     'Draft' => '',
     'Accepted' => 'A',
     'Rejected' => 'R',
     'Replaced' => 'P',
     'Deferred' => 'D',
     'Final' => 'F',
     );

# Index lists
my @file = ();
my @tag = ();
my @owner = ();

# Data tables
my (%eep, %num, %status, %type, %title, %owner); # $file indexed
my (%tag, %desc); # $status indexed
my (%email, %author); # $owner indexed

# Mapping of index name in HTML table spec to array variable
my %index =
    ('file' => \@file,
     'tag' => \@tag,
     'owner' => \@owner,
     );

# Mapping of HTML table column name to table variable
my %table =
    ('status' => \%status,
     'num' => \%num,
     'title' => \%title,
     'owner' => \%owner,
     'tag' => \%tag,
     'description' => \%desc,
     'email' => \%email,
     'author' => \%author,
     );

# Mapping of EEP Type:
my %type_map;
while (@type) {
    my ($type, $tag);
    ($type, $tag, @type) = @type;
    my $t = lc $type;
    $type_map{$t} = $tag;
    $tag{$t} = $tag;
    $desc{$t} = $type.$type_suffix;
    push @tag, $t;
}
@type = undef;

# Mapping of EEP Status:
my %status_map;
while (@status) {
    my ($status, $tag);
    ($status, $tag, @status) = @status;
    my $s = lc $status;
    $status_map{$s} = $tag;
    $tag{$s} = $tag;
    $desc{$s} = $status.$status_suffix;
    push @tag, $s unless $tag eq '';
}
@status = undef;
    
my @warnings = ();



# These set_* subroutines actually get their argument in $_

my $file; # heavily used hidden parameter

sub set_eep {
    unless (m|^ \s* \d+ \s* $|x) {
	push @warnings, "File $file: 'eep: $_' not decimal!";
    }
    if (defined $num{$file}) {
	push
	    @warnings,
	    "File $file: 'eep: $num{$file}' already seen in $num{$file}!";
    }
    push @file, $file;
    $eep{$file} = $_;
    $num{$file} = "[$_][EEP $_]";
 }

sub set_title {
    if (m| (?<!\\) \`\` |x) {
	push
	    @warnings,
	    "File $file: 'title:' contains double backtick!";
    }
    $title{$file} = "\`\` $_ \`\`";
}

sub set_author {
    my $author;
    my $email = '';
    my @authors = split m|(?<=\S) \s* , \s* (?=\S)|x;
    if ($authors[0] =~ m|^ (.*?) \s* (\< .* \>) \s* $|x) {
	($author, $email) = ($1, $2);
	if ($email =~ m| (?<!\\) \`\` |x) {
	    push
		@warnings,
		"File $file: 'title:' email contains double backtick!";
	}
	$email = "\`\` $email \`\`";
    } else {
	$author = $authors[0];
    }
    $owner{$file} = $author;
    if (defined $author{$author}) {
	if ($email ne $email{$author}) {
	    push
		@warnings,
		"File $file: 'author:' email $email ne $email{$author}!";
	}
    } else {
	push @owner, $author;
	$author{$author} = $author;
	$email{$author} = $email;
    }
}

sub set_status {
    m|^ ([^/]*) (/? [^\s]*) \s* ([^;]*)|x;
    my ($status, $tag, $desc) = ($1, $2, $3);
    my $s = $status_map{lc $status};
    unless (defined $s) {
	push @warnings, "File $file: 'status: $status' illegal!";
    }
    $status{$file} = $s.$tag;
    if ($tag ne '') {
	if (defined $tag{$tag}) {
	    if ($desc ne $desc{$tag}) {
		push
		    @warnings,
		    "File $file: 'status:' tag $desc ne $desc{$tag}!";
	    }
	} else {
	    push @tag, $tag;
	    $tag{$tag} = $tag;
	    $desc{$tag} = $desc;
	}
    }
}

sub set_type {
    my $type = $_;
    my $t = $type_map{lc $type};
    unless (defined $t) {
	push @warnings, "File $file: 'type: $type' illegal!";
    }
    $type{$file} = $t;
}

# Mapping of EEP header tag to handler set_* function
my %set =
    ('eep' => \&set_eep,
     'title' => \&set_title,
     'version' => 0,
     'last-modified' => 0,
     'author' => \&set_author,
     'discussions-to' => 0,
     'status' => \&set_status,
     'type' => \&set_type,
     'content-type' => 0,
     'requires' => 0,
     'created' => 0,
     'erlang-version' => 0,
     'post-history' => sub {},
     'replaces' => 0,
     'replaced-by' => 0,
     );

sub store_key {
    my ($hash, $key, $value) = @_;
    unless (defined $set{$key}) {
	push 
	    @warnings, 
	    "File $file: '$key:' unknown header - file skipped!";
    }
    if ($set{$key} || $check{$key}) {
	if (defined $$hash{$key}) {
	    push 
		@warnings, 
			"File $file: '$key:' double header - file skipped!";
	    return 0;
	}
	$$hash{$key} = $value;
    }
    return 1;
}

$\ = $lf;
open INDEX, '<', $index or die "Can't open $index: $!";

# Gather info from headers
#
opendir DIR, $dir or die "Can't open directory $dir: $!";
while ($file = readdir DIR) {
    next if $file =~ m|^ [.]{1,2} $|x;
    next unless $file =~ m|$suffix$|;
    open EEP, '<', $dir.$file or next;
    my (%hdr, $key, $value);
    my $ws; # leading whitespace
    LINE: while (<EEP>) {
	chomp;
	if (defined $ws) {
	    if (m|^$ws(\s.*)|) {
		# same leading whitespace as previous line - concatenate
		$value .= $1;
		next LINE;
	    } else {
		$ws = undef;
	    }
	}
	my $line = $_;
	#
	if (defined $key) {
	    # we now have a complete header in $key, $value
	    # check it and store in %hdr
	    $key = lc($key);
	    if ($key =~ m|^ eep \s+ (\d+) $|x) {
		# special treatment of EEP headline
		store_key \%hdr, 'eep', $1
		    or last LINE;
		store_key \%hdr, 'title', $value
		    or last LINE
	    } else {
		store_key \%hdr, $key, $value
		    or last LINE;
	    }
	    $key = undef;
	    $value = undef;
	}
	#
	if ($line =~ m|(^\s*)([^:]+):\s*(.*)|) {
	    # header line
	    ($ws, $key, $value) = ($1, $2, $3);
	} elsif ($line =~ m|\s* \* \s* \* \s* \* [\s\*]*|x
		 or $line =~ m|\s* - \s* - \s* - [-\s]*|x) {
	    # horizontal rule
	    next LINE;
	} elsif ($line =~ m|^\s*$|) { # blank line
	    # end of headers - process them all
	    next LINE unless defined($hdr{'eep'}); # still missing?
	    foreach (keys %set) {
		if ($set{$_} and !(defined $hdr{$_})) {
		    push
			@warnings,
			"File $file: '$_:' missing header - file skipped!";
		    last LINE;
		}
	    }
	    # call handler for all headers
	    while (($key, $_) = each %hdr) {
		&{$set{$key}} if $set{$key};
	    }
	    last LINE;
	} else {
	    push
		@warnings,
		"File $file: line '$line' illegal header - file skipped!";
	    last LINE;
	}
    }
    close EEP;
}

# post-processing pre-printing
foreach (@file) {
    $status{$_} = $type{$_}.$status{$_};
}
@file = sort @file;
@owner = sort @owner;



# Table printer
#
sub table {
    my ($caption, $ix, @cols) = @_;
    $ix = $index{lc $ix};
    return unless defined $ix;
    print "<TABLE border='1' summary='$caption'>";
    print "<CAPTION><STRONG>$caption</STRONG></CAPTION>";
    foreach (@cols) {
	print "<TH align='left'>$_</TH>";
    }
    foreach my $i (@$ix) {
	print "<TR>";
	foreach (@cols) {
	    my $td = $table{lc $_}{$i};
	    if (defined $td) {
		print "<TD align='left'>$td</TD>";
	    } else {
		print "<TD align='left'> </TD>";
	    }
	}
	print "</TR>";
    }
    print "</TABLE>";
}

# Traverse index file
#
while (<INDEX>) {
    chomp;
    if (m|^ [[] (.*) []] : \s* $me : (.+)? $|x) {
	if (defined $2) {
	    # [Table Caption]: <$me:index/col1/col2...>
	    &table($1, split(m|/|x, $2));
	} else {
	    # [Prefix] : <$me:>
	    foreach (@file) {
		print "[EEP $eep{$_}]: $_";
		print "    \"$1$eep{$_}: $title{$_}, $owner{$_}\"";
	    }
	}
	last unless(<INDEX>);
    } else {
	print;
    }
}

# Warnings appear at the end of the generated Markdown page
#
if (@warnings) {
    print "${lf}${lf}${lf}----${lf}Warnings${lf}--------${lf}";
    foreach (@warnings) {
	print "    $_";
    }
}
