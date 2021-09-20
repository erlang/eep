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
my @sources = @basenames;
foreach (@sources) { $_ .= $src_ext }
my $ix_base = $eeps_dir.'eep-0000';

my %rules =
    (# 'target' => [['build commands',...], 'dependencies',...]

     "README.html" =>
     [[@perl, $md, "README.md", \&redirect, "README.html"],
      "README.md", $mk, $md],

     $ix_base.$dst_ext =>
     [[@perl, $utf8, $ix, $ix_base.$src_ext, \&pipe,
       @perl, $utf8, $pre, \&pipe,
       @perl, $md, \&redirect, $ix_base.$dst_ext],
      @sources, $mk, $ix, $pre, $md],
     );
# Add rules for wildcard targets
foreach (@basenames) {
    my $src = $_.$src_ext;
    my $dst = $_.$dst_ext;
    unless (defined $rules{$dst}) {
	$rules{$dst} =
	    [[@perl, $utf8, $pre, $src, \&pipe,
	      @perl, $md, \&redirect, $dst],
	     $src, $mk, $pre, $md];
    }
}



# Find out what to do
my %mtime;
my %targets;
if (defined ($_ = $ARGV[0])) {
    # Sort out command line arguments
    if (/^(?:-a|--all)$/) {
	foreach (keys %rules) { # force build all
	    $targets{$_} = 1;
	}
    } elsif (/^(?:-c|--clean)$/) {
	my @files = keys %rules;
	print "rm @files\n";
	unlink @files;
	exit 0;
    } else {
	shift if /^--$/; # only targets after this
	foreach (@ARGV) {
	    defined $rules{$_} or die "Unknown target: $_";
	    $targets{$_} = 1; # force build
	}
	foreach (keys %rules) { # build only forced
	    delete $rules{$_} unless $targets{$_};
	}
    }
} else {
    # Build outdated targets
    &foreach_rules(sub {
	shift;
	foreach (@_) {
	    unless (defined $mtime{$_}) {
		if (-f) {
		    $mtime{$_} = (stat _)[9];
		} else {
		    $mtime{$_} = ''; # No such file
		}
	    }
	}
    });
}

# Call build function for all to rebuild
&foreach_rules(sub {
    my ($build, $target, @deps) = @_;
    my @build = @{$build};
    if ($targets{$target}) {
	#print "Target $target forced\n";
	&build(@build);
	return;
    }
    my $target_mtime = $mtime{$target};
    unless ($target_mtime) {
	#print "Target $target does not exist\n";
	&build(@build);
	return;
    }
    foreach (@deps) {
	$mtime{$_} or die "Missing dependency: $_";
	if ($mtime{$_} >= $target_mtime) {
	    #print "Target $target outdated vs $_\n";
	    &build(@build);
	    return;
	}
    }
});

exit 0;



# Toplevel per rule build, wait for last pid
sub build {
    ##print "build <@_>\n";
    open SAVEOUT, ">&STDOUT" or die "Can't save STDOUT: $!";
    my $last_pid = &recurse;
    close STDOUT;
    waitpid $last_pid, 0;
    open STDOUT, ">&SAVEOUT" or die "Can't restore STDOUT: $!";
}

# Pipe command to the next
sub pipe {
    ##print "pipe <@_>\n";
    my @cmd = @{+shift};
    print "@cmd | ";
    my $call_pid = &recurse;
    unless (my $pid = open STDOUT, '|-') {
        defined $pid or die "Can't fork: $!";
        exec {$cmd[0]} @cmd or die "Can't exec @cmd: $!";
    }
    return $call_pid;
}

# Redirect command to destination file.
# Next item is a filename, not command.
sub redirect {
    ##print "redirect <@_>\n";
    my @cmd = @{+shift};
    my $dst = shift;
    print "@cmd > $dst\n";
    my $pid;
    unless ($pid = open STDOUT, '|-') {
        defined $pid or die "Can't fork: $!";
        open STDOUT, ">$dst" or die "Can't open > $dst: $!";
        exec {$cmd[0]} @cmd or die "Can't exec @cmd: $!";
    }
    return $pid;
}

# Recursion helper, arguments are all remaining commands
# Call next command with its arguments as first parameter
# and remaining commands as the rest of the parameters.
# 
# &recurse(1, 2, 3, \&call, @commands) ->
#     return &call([1, 2, 3], @commands)
#
sub recurse {
    ##print "recurse <@_>\n";
    my @call;
    while (@_) {
	$_ = shift @_;
	if ((ref $_) eq 'CODE') {
	    unshift @_, \@call;
	    return &{$_};
	}
	push @call, $_;
    }
    die "Build spec error - no next command";
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
	push @names, $dir.$_ if &{$subst}();
    }
    closedir D;
    return @names;
}
