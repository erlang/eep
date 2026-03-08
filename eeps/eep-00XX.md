    Author: William Fank Thomé <contact(at)williamthome(dot)dev>
    Status: Active
    Type: Standards Track
    Created: 08-Mar-2026
    Erlang-Version: OTP-29.0
    Post-History: https://erlangforums.com/t/eep-singleton-binary-literal-types
****
EEP XX: Singleton Binary Literal Types
----

Abstract
========

This EEP extends [EEP 8][] to allow binary literals such
as `<<"start">>` and `<<"stop">>` as singleton types in
`-type`, `-spec`, `-callback`, and record field type
declarations. It also supports encoding annotations
(`<<"café"/utf8>>`) and sigil syntax (`~"hello"`) for
binary literal types. This brings binaries to parity
with atoms and integers, which already support singleton
type values in Erlang's type system.

Rationale
=========

[EEP 8][] introduced singleton types for atoms and
integers, allowing type specifications like
`'ok' | 'error'` and `0 | 1`. Binary strings, however,
have no such support despite being widely used as keys,
commands, and protocol tags.

Binary strings serve as discriminators in many Erlang
applications:

- Protocol tags: `<<"start">>`, `<<"stop">>`,
  `<<"ping">>`
- Map keys: `#{<<"action">> => ...}`
- Command identifiers in binary protocols
- JSON-like data structures with binary keys

Currently, a function that accepts only specific binary
values cannot express this constraint in its type
specification:

    %% Intent: only <<"start">> or <<"stop">> accepted
    -spec handle(binary()) -> ok.

With this EEP, the programmer can write:

    -type cmd() :: <<"start">> | <<"stop">>.
    -spec handle(cmd()) -> ok.

For binaries containing characters outside Latin-1,
encoding annotations allow explicit conversion:

    -type name() :: <<"café"/utf8>>.

Sigil syntax provides a concise alternative that
encodes as UTF-8:

    -type greeting() :: ~"hello".

This gives Dialyzer the information it needs to detect
calls with incorrect binary arguments, just as it already
does for atoms and integers.

Specification
=============

Grammar extension
-----------------

The `Binary` production in [EEP 8][] is extended with
new alternatives:

    Binary :: binary()
            | <<>>
            | <<_:Erlang_Integer>>
            | <<_:_*Erlang_Integer>>
            | <<_:Erlang_Integer, _:_*Erlang_Integer>>
            | <<Erlang_String>>
            | <<Erlang_String / Encoding>>
            | Sigil

    Encoding :: utf8 | utf16 | utf32 | latin1

    Sigil :: ~"Erlang_String"
           | ~b"Erlang_String"
           | ~B"Erlang_String"

Each alternative is a distinct form.  They cannot be
combined — for example, `<<$f, $o, "o">>` is binary
construction syntax valid in expressions but not in
type specifications.

The bare `<<Erlang_String>>` form requires all characters
in the range 0-255 (Latin-1).

The `<<Erlang_String / Encoding>>` form converts the
string using the named encoding at parse time.

The `Sigil` forms encode the string as UTF-8 at parse
time. String sigils (`~s"..."`) are rejected in type
specifications. No sigil suffixes are allowed.

Examples
--------

Supported forms:

    %% Bare string (Latin-1 characters only)
    -type cmd() :: <<"start">> | <<"stop">>.
    -type empty() :: <<>>. %% empty binary

    %% Encoding annotation
    -type utf8_name() :: <<"café"/utf8>>.
    -type utf16_tag() :: <<"hello"/utf16>>.
    -type latin1_tag() :: <<"hello"/latin1>>.

    %% Sigil (always UTF-8)
    -type greeting() :: ~"hello".
    -type utf8_cafe() :: ~"café".
    -type bsigil() :: ~b"hello".

    %% In -spec, -callback, records, and maps
    -spec handle(<<"start">> | <<"stop">>) -> ok.
    -callback on_event(<<"open">> | <<"close">>) -> ok.
    -record(msg, {tag :: <<"hello">> | <<"world">>}).
    -type headers() :: #{<<"accept">> => binary()}.

Not supported:

    %% Binary construction syntax
    -type t() :: <<$h, $i>>.        %% INVALID
    -type t() :: <<1, 2, 3>>.       %% INVALID

    %% Characters above 255 without encoding
    -type t() :: <<"café">>.        %% INVALID (á > 255)

    %% String sigils
    -type t() :: ~s"hello".         %% INVALID
    -type t() :: ~S"hello".         %% INVALID

    %% Sigil suffixes
    -type t() :: ~"hello"foo.       %% INVALID

    %% Unsupported bit type specifiers
    -type t() :: <<"hello"/integer>>.   %% INVALID
    -type t() :: <<"hello"/big>>.       %% INVALID

Restriction
-----------

The bare `<<"...">>` form requires all characters in the
range 0-255 (Latin-1), as each character maps to a single
byte. Strings containing characters above 255 are
rejected with a compilation error.

The `<<"..."/Encoding>>` form converts the string using
the named encoding (`utf8`, `utf16`, `utf32`, or
`latin1`) at parse time. Invalid characters for the
given encoding are rejected with a compilation error.

The sigil forms `~"..."`, `~b"..."`, and `~B"..."`
encode the string as UTF-8 at parse time. String sigils
(`~s"..."`, `~S"..."`) are rejected in type
specifications. No sigil suffixes are allowed.

Subtype absorption
------------------

A singleton binary type is a subtype of `binary()`. In
a type union, the supertype absorbs the subtype:

    <<"foo">> | binary()

is equivalent to:

    binary()

This follows the same rule that [EEP 8][] defines for
atoms and integers.

Abstract Forms
==============

A new abstract form node represents singleton binary
types:

    {bin_type, ANNO, Bin}

where `Bin` is a `binary()` value.

For example, the type `<<"hello">>` is represented as:

    {bin_type, Anno, <<"hello">>}

All syntax forms — bare `<<"...">>`, encoded
`<<"..."/utf8>>`, and sigil `~"..."` — produce the
same `{bin_type, ANNO, Bin}` node. Encoding is applied
at parse time and is not preserved in the AST.

This node appears wherever a type form is expected,
alongside existing singleton nodes `{atom, ANNO, Atom}`
and `{integer, ANNO, Integer}`.

The existing `{type, ANNO, binary, [...]}` node for
structural binary types (`binary()`, `<<_:N>>`, etc.)
is unchanged.

Dialyzer Support
================

Dialyzer tracks binary literal values using an internal
representation that extends the existing bitstring type.

Value constructor
-----------------

A new constructor `t_binary_val/1` creates a binary type
that tracks the exact value:

    t_binary_val(<<"hello">>)

Values of the same bit size are kept as an ordered set.
When the set exceeds the internal size limit, or when
values of different bit sizes are combined, the type
falls back to the structural `t_bitstr/2` representation.

Type operations
---------------

The standard type operations handle binary values:

- **Union** (`t_sup`): merges value sets; falls back to
  structural type when sizes differ or sets overflow.
- **Intersection** (`t_inf`): computes the set
  intersection of tracked values.
- **Subtraction** (`t_subtract`): computes the set
  difference of tracked values.
- **Elements** (`t_elements`): decomposes a binary value
  set into individual singleton types.
- **Singleton test** (`is_singleton_type`): returns
  `true` for a single tracked binary value.

Map key support
---------------

Binary literal types can be used as map keys. Dialyzer
expands binary value sets when separating map key types,
enabling precise tracking of map entries keyed by
specific binary values.

Syntax Tools
============

The `erl_syntax` module provides a new node type
`binary_literal_type` with the following interface:

    erl_syntax:binary_literal_type(Value) -> syntaxTree()
    erl_syntax:binary_literal_type_value(Node) -> binary()

The node is classified as a leaf node. The functions
`concrete/1` and `is_literal/1` recognize it as a
literal form.

The `erl_prettypr` module always renders the node as
`<<"value">>` regardless of the original syntax used
(bare, encoded, or sigil).

Backward Compatibility
======================

For code that does not use this feature, nothing changes.
The new AST node `{bin_type, ANNO, Bin}` may require
updates to parse transforms and tools that pattern-match
on type forms.

Reference Implementation
========================

A [reference implementation][Implementation PR] is available.

[Implementation PR]: https://github.com/erlang/otp/pull/10816
    "Implementation Pull Request"

[EEP 8]: eep-0008.md
    "EEP 8: Types and function specifications"

Copyright
=========

This document is placed in the public domain or under the
CC0-1.0-Universal license, whichever is more permissive.

[EmacsVar]: <> "Local Variables:"
[EmacsVar]: <> "mode: indented-text"
[EmacsVar]: <> "indent-tabs-mode: nil"
[EmacsVar]: <> "sentence-end-double-space: t"
[EmacsVar]: <> "fill-column: 70"
[EmacsVar]: <> "coding: utf-8"
[EmacsVar]: <> "End:"
[VimVar]: <> " vim: set fileencoding=utf-8 expandtab shiftwidth=4 softtabstop=4: "
