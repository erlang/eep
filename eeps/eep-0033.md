    Author: Raimo Niskanen <raimo(at)erlang(dot)org>
    Status: Active
    Type: Process
    Created: 31-Mar-2010
    Post-History:
    Replaces: 2, 3
****
EEP 33: Sample Markdown EEP Template
----



Abstract
========

This EEP provides a boilerplate or sample template for creating your own
[Markdown][] EEPs. In conjunction with the content guidelines in [EEP 1][],
this should make it easy for you to conform your own EEPs to the format
outlined below.

> Note: if you are reading this EEP via the web, you should first
> grab the plaintext [source of this EEP][eep.md] in order to complete the
> steps below.  DO NOT USE THE HTML FILE AS YOUR TEMPLATE!


This document is based on [PEP 9][].



Rationale
=========

EEP submissions come in a wide variety of forms, not all adhering to the
format guidelines set forth below.  Use this template, in conjunction with
the content guidelines in [EEP 1][], to ensure that your EEP submission
won't get automatically rejected because of form.



How to Use This Template
========================

To use this template you must first decide whether your EEP is going to be
an Process or Standards Track EEP.  Most EEPs are Standards Track because
they propose a new feature for the Erlang language or standard library.
When in doubt, read [EEP 1][] for details or contact the EEP editors
<eeps@erlang.org>.

Once you've decided which type of EEP yours is going to be, follow the
directions below.

-   Make a copy of [this file][eep.md] (.md file, not HTML!) and perform the
    following edits.

-   Replace the "EEP 33: " header with "EEP XXX: " and the title of your EEP,
    i.e use 'XXX' until you have an assigned EEP number.

-   Change the Author header to include your name, and optionally your
    email address.  Be sure to follow the format carefully: your name
    must appear first, and it must not be contained in parentheses.
    Your email address may appear second (or it can be omitted) and if
    it appears, it must appear in angle brackets.  It is recommended
    to obfuscate your email address. The authors can be a comma separated
    list in which the last author is the EEP owner.

-   If there is a mailing list for discussion of your new feature, add
    a Discussions-To header right after the Author header.  You should
    not add a Discussions-To header if the mailing list to be used is
    <erlang-questions@erlang.org>, or if discussions should be sent to
    you directly.  Most Process EEPs don't have a Discussions-To header.

-   Change the Status header to "Draft".

-   For Standards Track EEPs, change the Type header to "Standards Track".

-   For Process EEPs, change the Type header to "Process".

-   For Standards Track EEPs, if your feature depends on the acceptance
    of some other currently in-development EEP, add a Requires header right
    after the Type header.  The value should be the EEP number of the EEP
    yours depends on.  Don't add this header if your dependent feature is
    described in a Final EEP.

-   Change the Created header to today's date.  Be sure to follow the format
    carefully: it must be in dd-mmm-yyyy format, where the mmm is the
    3 English letter month abbreviation, e.g. one of Jan, Feb, Mar, Apr,
    May, Jun, Jul, Aug, Sep, Oct, Nov, Dec.

-   For Standards Track EEPs, after the Created header, add a Erlang-Version
    header and set the value to the next planned version of Erlang, i.e.
    the one your new feature will hopefully make its first appearance in.
    Thus, if the last version of Erlang/OTP was R13B-3 and you're hoping
    to get your new feature into R13B-4 set the version header to:
   
        Erlang-Version: R13B-4

-   Leave Post-History alone for now; you'll add dates to this header each
    time you post your EEP to <erlang-questions@erlang.org>.  E.g. if you
    posted your EEP to the list on August 14, 2009 and September 3, 2009,
    the Post-History header would look like:
   
        Post-History: 14-Aug-2009, 03-Sept-2009
   
    You must manually add new dates and check them in.  If you don't have
    check-in privileges, send your changes to the EEP editor.

-   Add a Replaces header if your EEP obsoletes an earlier EEP.  The value
    of this header is the number of the EEP that your new EEP is replacing.
    Only add this header if the older EEP is in "final" form, i.e. is either
    Accepted, Final, or Rejected.  You aren't replacing an older open EEP
    if you're submitting a competing idea.

-   Now write your Abstract, Rationale, and other content for your EEP,
    replacing all this gobbledygook with your own text.  Be sure to adhere
    to the format guidelines below, specifically on the prohibition of tab
    characters and the indentation requirements.

-   Update your References and Copyright section.  Usually you'll place
    your EEP into the public domain, in which case just leave the "Copyright"
    section alone.  Alternatively, you can use the [Open Publication
    License][OPL] or the [Creative Commons Attributions 3.0 License][CCA3.0],
    but public domain is still strongly preferred.

-   Leave the little [Emacs turd][] at the end of this file alone, with it
    you get a good mode and character encoding, and can e.g fix a
    paragraph using `fill-paragraph` (default `[ESC] q`).

-   Send your EEP submission to the EEP editors <eeps@erlang.org>.



Markdown EEP Formatting Requirements
====================================

See the [Markdown][] Syntax for general formatting syntax.  On top of
this Markdown EEPs has these requirements:

The first lines of the EEP is for EEP index generator parsing and the
Markdow preprocessing so it must look like the first 10 lines of
[this file][eep.md], with that specific style of horizontal rule
and header 2 title.  Your EEP may have more or less header lines.

EEP toplevel headings are type H1 i.e `====` underlined.  The initial
letter of each word must be capitalized as in book titles.

Acronyms should be in all capitals.

Code samples inside sections should be indented 4 spaces.

You must use three blank lines before all H1 headings, and two before
all H2 headings.

You must adhere to the Emacs convention of adding two spaces at the
end of every sentence.  You should fill your paragraphs to column 70,
but under no circumstances should your lines extend past column 79.
If your code samples spill over column 79, you should rewrite them.

Tab characters must never appear in the document at all.

When referencing an external web page in the body of an EEP, you
should include the title of the page in the text, with a footnote
reference to the URL.  Do not include the URL in the body text of the
EEP.  E.g:

    Refer to the [Erlang Language web site][1] for more details.

    :

    [1]: http://www.erlang.org
        "Erlang Programming Language"

Footnote reference definitions should be placed second last in the
document, right before the "Copyright" section and the Emacs magic.
Note that these references are invisible in the by [Markdown][]
generated HTML.

When referring to another EEP, include the EEP number in the body text
using an implicit link name footnote, such as `[EEP 1][]`.  The title
may optionally appear.  The footnote body should include the EEP's
title and author, and it should refer to its URL.

> NOTE: The URL is relative to the current URL and the build 
> tools will fix it to point to the .html file.
> 

Example:

    Refer to [EEP 1][] for more information about EEP style

    :

    [EEP 1]: eep-0001.md
        "EEP 1, EEP Purpose and Guidelines, Gustafsson"

EEP numbers in URLs must be padded with zeros from the left, so as to
be exactly 4 characters wide, however EEP numbers in the text are
never padded.



[eep.md]: eep-0033.md
    "EEP Source"

[EEP 1]: eep-0001.md
    "EEP Purpose and Guidelines, Gustafsson"

[PEP 9]: http://www.python.org/dev/peps/pep-0009/
    "Sample Plaintext PEP Template, Warsaw"

[Markdown]: http://daringfireball.net/projects/markdown/
   "Markdown Home Page"

[OPL]: http://www.opencontent.org/openpub/
    "Open Publication License"

[CCA3.0]: http://creativecommons.org/licenses/by/3.0/
    "Creative Commons Attribution 3.0 License"

[Emacs turd]: http://www.gnu.org/software/emacs/manual/html_node/emacs/Specifying-File-Variables.html
    "Specifying local file variables for Emacs"



Copyright
=========

This document has been placed in the public domain.



[EmacsVar]: <> "Local Variables:"
[EmacsVar]: <> "mode: indented-text"
[EmacsVar]: <> "indent-tabs-mode: nil"
[EmacsVar]: <> "sentence-end-double-space: t"
[EmacsVar]: <> "fill-column: 70"
[EmacsVar]: <> "coding: utf-8"
[EmacsVar]: <> "End:"
[VimVar]: <> " vim: set fileencoding=utf-8 expandtab shiftwidth=4 softtabstop=4: "
