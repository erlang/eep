    Author: Viktor Söderqvist <viktor(dot)zuiderkwast(at)se>
    Status: Draft
    Type: Standards Track
    Created: 18-Jun-2021
    Erlang-Version: 25.0
    Post-History: 18-Jun-2021
****
EEP XXX: Module for lists of maps
----



Abstract
========

This EEP adds functions operating on lists of maps, analogous to the
functions `lists:key*` operating on lists of tuples, in a new module
in stdlib.



Specification
=============

There shall be a module `maplists` in stdlib with functions analoguous
to the `lists:key*` and `lists:ukey*` functions, operating on lists of
maps.  In place of the `N` argument (referring to key position in the
tuples), the `maplists` functions take a map key instead.  The module
shall contain analogues of all the functions in the `lists` module
with a name containing "key", except `keysearch/3` (which is retained
only for backward compatibility).  The function names shall be the
same as of those in the `lists` module.  The complete list of
functions is:

* keydelete/3
* keyfind/3
* keymap/3
* keymember/3
* keymerge/3
* keyreplace/4
* keysort/2
* keystore/4
* keytake/3
* ukeymerge/3
* ukeysort/2

Each function in the `maplists` module shall ignore list elements
which are not maps, or which are maps but don't contain the requested
key, if and only if the corresponding function in the `lists` module
ignores list elements which are not tuples.  Likewise, a function in
`maplists` which affects all elements (namely `keymap/3`, `keymerge/3`,
`keysort/2`, `ukeymerge/3` and `ukeysort/2`) shall crash when list
elements other than maps or maps which don't contain the requested key
are present, if and only if the corresponding function in the lists
module crashes when the list contains elements which are not tuples.

The matching of map keys should use match semantics (`=:=`) rather
than equal semantics (`==`) used for the `lists:key*` functions.



Motivation
==========

One of the motivations for adding maps to Erlang was to "be a
complement to records and supersede them where suitable" ([EEP 43][]).
Maps and records both have their pros and cons and time has shown that
both are being used side by side in old and new code bases.

Stdlib's `lists` module contains functions for working with lists of
any term, most of them well-known from functional programming
langauges such as ML and Haskell.  These include map, filter, foldl,
partition and similar.  The [zip][] functions (`zip/2`, `zip3/3`,
`unzip/1` and `unzip3/1`) work with lists of tuples, but since the
they're well-known and central to functional langauges, they fit well
together with the other list functions.

The `lists:key*` functions stick out though, since they are
specializations of list functions to work with lists of tuples.  The
key position parameter (`N`) is used in a similar way as for ETS
tables (the `keypos` option).  When working with lists of records, the
`#Record.Field` notation is often used as the `N` argument.

The functions for working with lists of tuples have proven useful, but
there aren't any functions for working with lists of maps in the same
way.

Such functions have been suggested from time to time, first in the
erlang-questions mailing list thread ["[erlang-questions] analogue of
lists:keyfind and other lists:key\*\*\* functions for lists which
contain maps"][2014] in 2014 (soon after maps were introduced) and
then again in 2019 ["[erlang-questions] lists module functions for
maps?"][2019].  Recently, the topic has come up in the OTP pull
request ["Add new lists:mapkeyfind/3 function to map finding
\#4831"][OTP-PR 4831].



Rationale
=========

The function names and the order of arguments are picked to match
those of the list-of-tuples functions as closely as possible.  The
decision for functions to ignore list elements which are not maps is
also made to resemble the behaviour of the list-of-tuples functions.
This consistency allows for working with lists of maps and lists of
records in a similar way and to replace records with maps with the
least surprise possible.

The use of match semantics (`=:=`), rather than equal semantics (`==`)
used for `lists:key*` functions, is chosen because the choise of equal
semantics is considered a mistake.  The difference can be explained in
the top of the manual, just like it is for `ordsets` vs `sets`.

The module name `maplists` follows a similar naming style as
`proplists` (lists of properties) and is in plural like `lists`,
`maps` and others in stdlib.

Rejected alternatives:

*   **Allowing `lists:keyfind/3` to work on maps**

    It would be possible to allow the `lists:key*` functions to work
    on both tuples and maps simultaneously.  When a map is encoutered,
    the `N` parameter is treated as a map key name and when a tuple is
    encoutered `N` is a tuple element position.

    Apart from some corner cases not being backward compatible (such
    as `lists:keyfind(2, id, [])` now returning `false` instead of
    raising a `badarg` error, as noted by [Lukas Larsson in
    erlang-questions in 2014][2014-1]), it is unlikely that anyone
    wants to mix records and maps in the same list and it was
    described as "making a Frankenstein" by "John Dow" in [this email
    from 2014][2014-2].

*   **Adding `lists:mapfind/1`**

    Adding map variants of these functions in the `lists` module would
    be possible, but it's not desirable, because "adding tuple support
    to the lists module was a mistake and that it should instead have
    been a separate module such as `tuplelist`" (Lukas Larsson in
    [OTP-PR 4831][]).

*   **What about adding it to the maps module?**

    The `maps` module is for functions working directly with maps, not
    lists of maps.

*   **Why isn't `lists:search(fun(Map) -> maps:get(Key,Map) =:= Value end,
    ListOfMaps)` good enough?**

    The same can be asked about the `lists:key*` functions.  They are
    specializations of lists functions, but they have proven useful
    and are more efficient than the `fun` alternatives since they are
    implemented as BIFs.



Reference Implementation
========================

[Lists of Maps][lom], by Craig Everett, has most of the functions in
this EEP, with the following differences:

* The module name is different.
* The function names don't have the "key" prefix.
* Most (if not all) of the functions in this implementation crash when
  a list element which is not a map is encountered.  Likewise, if a
  map is lacking the requested key.
* The functions `ukeymerge/3` and `ukeysort/2` are missing.

[EEP 43]: eep-0043.md
    "EEP 43, Maps, Björn-Egil Dahlberg"

[zip]: https://en.wikipedia.org/wiki/Convolution_(computer_science)
    "Convolution (computer science), Wikipedia"

[2014]: https://erlang.org/pipermail/erlang-questions/2014-November/081865.html
    "[erlang-questions] analogue of lists:keyfind and other
    lists:key*** functions for lists which contain maps"

[2014-1]: https://erlang.org/pipermail/erlang-questions/2014-November/081869.html
    "[erlang-questions] analogue of lists:keyfind and other
    lists:key*** functions for lists which contain maps"

[2014-2]: https://erlang.org/pipermail/erlang-questions/2014-November/081875.html
    "[erlang-questions] analogue of lists:keyfind and other
    lists:key*** functions for lists which contain maps"

[2019]: https://erlang.org/pipermail/erlang-questions/2019-September/098461.html
    "[erlang-questions] lists module functions for maps?"

[OTP-PR 4831]: https://github.com/erlang/otp/pull/4831
    "Add new lists:mapkeyfind/3 function to map finding #4831"

[lom]: https://gitlab.com/zxq9/lom/
    "Lists of Maps"



Copyright
=========

This document is placed in the public domain or under the CC0-1.0-Universal
license, whichever is more permissive.



[EmacsVar]: <> "Local Variables:"
[EmacsVar]: <> "mode: indented-text"
[EmacsVar]: <> "indent-tabs-mode: nil"
[EmacsVar]: <> "sentence-end-double-space: t"
[EmacsVar]: <> "fill-column: 70"
[EmacsVar]: <> "coding: utf-8"
[EmacsVar]: <> "End:"
[VimVar]: <> " vim: set fileencoding=utf-8 expandtab shiftwidth=4 softtabstop=4: "
