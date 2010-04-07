#! /usr/bin/perl
##
## Build script, since make is sooo unportable.
##
## Copyright 2010: Erlang/OTP, Raimo Niskanen
## This document has been placed in the public domain.
#
#
# $0                                Build all outdated targets
# $0 -a | --all                     Force build of all targets
# $0 -c | --clean                   Remove all targets
# $0 [--] Target [Target2 ...]      Force build of only target(s)

use strict;

my $mk = $0;
my @perl = ("perl", "-w");
my $utf8 = '-CSD'; # Perl UTF-8 command line switch
my $md = "md/Markdown.pl";
my $ix = "eep-index.pl";
my $pre = "eep-pre.pl";

my $eeps_dir = 'eeps/';
my $src_ext = '.md';
my $dst_ext = '.html';
my @basenames =
    &dir_files($eeps_dir, sub {s/^(eep-\d+)$src_ext$/$1/});
my $eep_0 = $eeps_dir.'eep-0000';

my %rules =
    (
     
     "README.html" => #target
     [[\&redirect, "README.html", @perl, $md, "README.md"], #build
      "README.md", $mk, $md], #deps

     $eep_0.$dst_ext => #target
     [[\&pipe, @perl, $utf8, $ix, $eep_0.$src_ext,
       \&pipe, @perl, $utf8, $pre,
       \&redirect, $eep_0.$dst_ext, @perl, $md], #build
      $eep_0.$src_ext, $mk, $ix, $pre, $md], #deps
     
     );
# Add rules for wildcard targets
foreach (@basenames) {
    my $src = $_.$src_ext;
    my $dst = $_.$dst_ext;
    unless (defined $rules{$dst}) {
	$rules{$dst} = #target
	    [[\&pipe, @perl, $utf8, $pre, $src,
	      \&redirect, $dst, @perl, $md], #build
	     $src, $mk, $pre, $md]; #deps
    }
}



my %mtime;
my %targets;
if (defined ($_ = $ARGV[0])) {
    if (/^(-a|--all)$/) {
	foreach (keys %rules) { # force build all
	    $targets{$_} = 1;
	}
    } elsif (/^(-c|--clean)$/) {
	my @files = keys %rules;
	print "rm @files\n";
	unlink @files;
	exit 0;
    } else {
	shift if /^--$/; # only targets after this
	foreach (@ARGV) {
	    $targets{$_} = 1; # force build
	}
	foreach (keys %rules) { # build only forced
	    delete $rules{$_} unless $targets{$_};
	}
    }
} else {
    # Look up modification time for all files
    &foreach_rules(sub {
	shift;
	foreach (@_) {
	    if (!(defined $mtime{$_}) && -f) {
		$mtime{$_} = (stat _)[9];
	    }
	}
    });
}

# Call build function for all that need rebuild
&foreach_rules(sub {
    my ($build, $target, @deps) = @_;
    my @build = @{$build};
    if  ($targets{$target} || ! -f $target) {
	#print "Target $target does not exist\n";
	&build(@build);
	return;
    }
    my $target_mtime = $mtime{$target};
    foreach my $d (@deps) {
	-f $d or die "Missing dependency: $d";
	if ($mtime{$d} >= $target_mtime) {
	    #print "Target $target outdated vs $d\n";
	    &build(@build);
	    return;
	}
    }
});

exit 0;



# Toplevel build, wait for last pid in pipe
sub build {
    my $func = shift;
    open SAVEOUT, ">&STDOUT" or die "Can't dup STDOUT: $!";
    my $last_pid = &{$func};
    close STDOUT;
    waitpid $last_pid, 0;
    open STDOUT, ">&SAVEOUT" or die "Can't dup SAVEOUT: $!";
}

# Make a pipe of the arguments to the next subroutine
sub pipe {
    my @call;
    my $func;
    while (@_) {
        my $x = shift;
        if (ref $x) {
	    # next subroutine found
            $func = $x;
            last;
        } else {
            push @call, $x;
        }
    }
    print "@call | ";
    my $last_pid;
    if (defined $func) {
	print "@call | ";
	$last_pid = &{$func};
    } else {
	print "@call\n";
    }
    my $pid;
    unless ($pid = open STDOUT, '|-') {
        defined $pid or die "can't fork: $!";
        exec {$call[0]} @call or die "can't exec @call: $!";
    }
    return $last_pid if defined $last_pid;
    return $pid;
}

# Redirect command to destination file
sub redirect {
    my $dst = shift;
    print "@_ > $dst\n";
    my $pid;
    unless ($pid = open STDOUT, '|-') {
        defined $pid or die "can't fork: $!";
        open STDOUT, ">$dst" or die "can't open > $dst: $!";
        exec {$_[0]} @_ or die "can't exec @_: $!";
    }
    return $pid;
}

# Helper loop subroutine over %rules
sub foreach_rules {
    my ($func) = @_;
    foreach my $target (sort (keys %rules)) {
	my ($build, @files) = @{$rules{$target}};
	&{$func}($build, $target, @files);
    }
}

# Filename wildcard
sub dir_files {
    my ($dir, $subst) = @_;
    my @names;
    opendir D, $dir || die "Can't opendir $dir: $!";
    while ($_ = readdir(D)) {
	push @names, $dir.$_ if &{$subst};
    }
    closedir D;
    return @names;
}
