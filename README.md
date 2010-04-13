Erlang Enhancement Process
--------------------------

This repository contains in the subdirectory eeps/ the EEPs (Erlang
Extension Proposals), in [Markdown][MD] (*.md) format produced in the
[Erlang Enhancement Process][EEP].

It also contains a version of a [Markdown.pl][] script in subdirectory
md/ that can be used, for example with the also contained Perl [build
script][build.pl] and some helper scripts, to produce HTML versions of
the *.md EEPs.

Type `perl build.pl` or `./build.pl` depending on your environment to
rebuild all HTML that needs to be rebuilt. A reasonable 'perl' (5.8) is all
that is needed.

Patch suggestions to this repository should be sent to <eeps@erlang.org>
(remember to subscribe to the list first) as stated in the
[Erlang Enhancement Process][EEP].



[MD]: http://daringfireball.net/projects/markdown/
    "The Markdown Project"

[Markdown.pl]: md/Markdown.pl
    "Markdown.pl"

[EEP]: http://demo.erlang.org/eep.html
    "Erlang Enhancement Process"

[build.pl]: build.pl
    "Perl build script to overcome Makefile inportability"



Copyright
---------

This document has been placed in the public domain.

### Author
Erlang/OTP, Raimo Niskanen, 2010



[EmacsVar]: <> "Local Variables:"
[EmacsVar]: <> "mode: indented-text"
[EmacsVar]: <> "indent-tabs-mode: nil"
[EmacsVar]: <> "sentence-end-double-space: t"
[EmacsVar]: <> "fill-column: 70"
[EmacsVar]: <> "coding: utf-8"
[EmacsVar]: <> "End:"
