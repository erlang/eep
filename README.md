Erlang Enhancement Process
--------------------------

This repository contains in the subdirectory eeps/ the EEPs (Erlang
Extension Proposals), in [Markdown][MD] (`*.md`) format produced in the
[Erlang Enhancement Process][EEP].

The [EEP Index][EEP 0] in [EEP 0][] gathers all EEPs and is built with
the tools in the following paragraphs from the EEPs themselves.

This repository also contains a version of a [Markdown.pl][] script in
subdirectory `md/` that can be used, for example with the also contained
Perl [build script][build.pl] and some helper scripts,
to produce HTML versions of the `*.md` EEPs.

Type `perl build.pl` or `./build.pl` depending on your environment to
rebuild all HTML that needs to be rebuilt. A reasonable `perl` (5.8)
is all that is needed.

Patch suggestions to this repository should be sent to <eeps@erlang.org>
(remember to subscribe to the list first) as stated in the
[Erlang Enhancement Process][EEP].



[MD]: http://daringfireball.net/projects/markdown/
    "The Markdown Project"

[Markdown.pl]: md/Markdown.pl
    "Markdown.pl"

[EEP]: http://www.erlang.org/eep.html
    "Erlang Enhancement Process"

[build.pl]: build.pl
    "Perl build script to overcome Makefile inportability"

[EEP 0]: http://erlang.org/eep/eeps/eep-0000.html
    "EEP 0: Index of EEPS"


Copyright
---------

This document is placed in the public domain or under the CC0-1.0-Universal
license, whichever is more permissive.

### Author
Erlang/OTP, Raimo Niskanen, 2010, 2018



[EmacsVar]: <> "Local Variables:"
[EmacsVar]: <> "mode: indented-text"
[EmacsVar]: <> "indent-tabs-mode: nil"
[EmacsVar]: <> "sentence-end-double-space: t"
[EmacsVar]: <> "fill-column: 70"
[EmacsVar]: <> "coding: utf-8"
[EmacsVar]: <> "End:"
