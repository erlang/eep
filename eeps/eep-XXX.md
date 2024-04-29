    Author: Isabell Huang <isabell.huang@ericsson.com>
    Status: Draft
    Type: Standards Track
    Created: 18-Mar-2024
    Post-History:
****
EEP XXX: Nominal Type
----

Abstract
========

This EEP proposes the addition of nominal types `-nominal` to Erlang, where
the changes can be applied exclusively to Dialyzer (modulo parsing).  As a
side effect, nominal types can encode opaque types, which improves Dialyzer's
maintainability.  Nominal typing has been used in dynamic languages before,
such as [Flow][1], or encoded in  [TypeScript] and static languages such as
[Rust][2] ([tuples are structurally typed, structs are nominally typed][3]),
[OCaml][4] ([records are nominally typed, objects are structurally typed][5]),
Scala, and/or Swift.

Rationale
=========

Erlang is a dynamically typed language with many optional tools for static
type checking.  Existing tools employ many different type paradigms,
including success typing, gradual typing, and set-theoretical type systems,
etc.  While all these type systems differ in how they approach type
checking and inference, they are all structural type systems.  Two types
are seen as equivalent if their structures are the same.  Type comparison
are based on the structures of the types, not on how the user explicitly
defines them.  For example, in the following example, `meter()` and
`foot()` are equivalent in a structural type system, because they have
the same structure.  The two types can be used interchangeably.  Neither
of them differ from the basic type `integer()`.

    -type meter() :: integer().
    -type foot() :: integer().

Nominal typing is an alternative type system, where two types are equivalent
if and only if they are declared with the same type name.  If the example
above is in a nominal type system, `meter()` and `foot()` are no longer
compatible because they have different names.  Whenever a function expects
type `meter()`, passing in type `foot()` would result in an error.  Nominal
typing can prevent accidental misuse of types with the same structure.  It
is a useful feature orthogonal to all the existing type systems for Erlang.

Nominal types can be seen as opaques with relaxed semantics.  Nominals and
opaques have in common that types that differ on the name are not compatible.
Nominals allow pattern matching on the internal structure, which is forbidden
with opaques.  Apart from this, by encoding opaques in terms of nominal
types, we make Dialyzer faster and easier to maintain.

Specification
========================

This EEP proposes one new syntax `-nominal` for declaring nominal types.  It
can be used as in the following example:

    -module(example).

    % Declaration of nominal types
    -nominal meter() :: integer().
    -nominal foot() :: integer().

    % Constructor for nominal types
    -spec meter_ctor(integer()) -> meter().
    meter_ctor(X) -> X.

    % Function that has its input and/or output as nominal types
    -spec meter_to_foot(meter()) -> foot().
    meter_to_foot(X) -> X * 3.

Nominal types are declared and used in the same way as other user-defined
types.  The compiler recognizes the syntax, but does not perform extra
type-checking.  Type checking for nominal types is done in Dialyzer.

According to nominal type-checking rules, if two nominal types have different
names, and one is not nested in the other, then they are not compatible.  
For instance, if we continue from the example above:

    -spec foo() -> foot().
    foo() -> meter_ctor(24). 
    % Output type: meter(). 
    % Expected type: foot().
    % Result: Dialyzer error.

Dialyzer returns the following error for the function `foo()`:

    Invalid type specification for function example:foo/0.
    The success typing is example:foo
          () ->
             nominal({'example', 'meter', 0, 'transparent'}, integer())
    But the spec is example:foo
          () -> foot()
     The return types do not overlap
On the other hand, nominal type-checking does not force the user to wrap or
annotate values as nominal types. In the following example, Dialyzer does
not return any error for the function `bar()`. The spec for `meter_to_foot()`
expects a `meter()` type as input.  Passing in a `integer()` type is allowed,
because `meter()` is defined to have type `integer()`.  Only if the input
is of a different basic type, for example `atom()`, Dialyzer will reject it.

    -spec bar() -> foot().
    bar() -> meter_to_foot(24). 
    % Input type: integer(). 
    % Expected type: meter().
    % Result: No error.

When a nominal type is expected, passing in a type with the same structure
is also allowed.  In the following example, Dialyzer does not return any
error for the function `qaz()`.  The spec for `meter_ctor()` expects a
`integer()` type as input. Passing in a `meter()` type is allowed, because
`meter()` is defined to have type `integer()`.  Similarly, passing in a
type `foot()` is also allowed when `integer()` is expected.

    -spec qaz() -> integer().
    qaz() -> meter_ctor(meter_ctor(24)). 
    % Input of the outer meter_ctor(): meter(). 
    % Expected type: integer().
    % Result: No error. 

It is also worth noting that nested nominal types are supported.  In the
following example:

    -nominal state() :: integer().
    -nominal container() :: state().
    -nominal record_container() :: #{a => state(), b => [container()|atom()]}.

Nominal type-checking in Dialyzer correctly recognizes that `container()`
can be safely used whenever a type `state()` is expected, just as `state()`
can be safely used when a type `integer()` is expected.  Using `[state()]`
as the second parameter of `record_container()`'s construction is allowed,
even though `container()` and `state()` have different names.

Nominal Type-Checking Rules
----------------------------

In order to specify nominal type-checking rules, there are three terms that
need to be defined. The scope of these definitions are local to this EEP.

For two nominal types `s()` and `t()`, `s()` is a **nominal subtype** of
`t()`, and `t()` is a **nominal supertype** of `s()` if `t()` is nested
in `s()`.

- Cases where `s()` is a nominal subtype of `t()`:
    - `t()` can be directly nested in `s()`.

          -nominal s() :: t().
    - `t()` can be nested in other nominal type(s), which is then nested
    in `s()`.

          -nominal s() :: nominal_1().
          -nominal nominal_1() :: nominal_2().
          -nominal nominal_2() :: t().

A non-nominal type is **compatible** with a nominal or non-nominal type
if their structures are deemed compatible by the type-checker. 

For Dialyzer, two types are compatible if they share common values. The
function `erl_types:t_inf/2` computes the intersection of 2 types. Two
types that have a non-empty intersection are structurally compatible.

- Examples:
    - 4711 and 42 are not structurally compatible. (No integer value can be
    both 4711 and 42.)
    - 4711 and `integer()` are structurally compatible. (Their intersection
    is the value 4711.)
    - `list(any_type)` and `[]` are structurally compatible. (Their intersection
    is `[]`.)
    - `-nominal t() :: integer()` and 4711 are structurally compatible. (Their
    intersection is the value `t() :: 4711`.)
    - `-nominal t() :: non_neg_integer()` and `neg_integer()` are not
    structurally compatible. (No value belongs to both `non_neg_integer()` and
    `neg_integer()`.)

****
The nominal type-checking rules proposed by this EEP can be summarized as
follows:

A function that has a `-spec` that states an argument or a return type to be
nominal type `a/0` (or any other arity), accepts or may return:

- Nominal type `a/0`
- A nominal supertype or subtype of `a/0`
- A compatible structural type.

A function that has a `-spec` that states an argument or a return type to be
a structural type `b/0` (or any other arity), accepts or may return:

- A compatible structural type.
- A compatible nominal type.

A supertype is allowed when expecting a nominal subtype for the following 3
reasons (even though subtyping relation is not symmetric):

- To minimize the users' effort of converting values to nominal types or
rewriting specifications.
- Dialyzer (success typing) allows for it among structural types. Most
existing type-checkers for Erlang allow for it as well.
- To make nominal type-checking more flexible than restrictive.


Optimizing Type-Checking for Opaques
=======================================

One benefit of this implementation of nominal types is that they can encode
opaques, so the maintenance effort is reduced for the OTP team. The logic
for nominal types replaces completely the logic for opaques in Dialyzer.
Furthermore, the implementation makes type checking opaques to run in
linear time, instead of quartic time.

This update comes with many benefits in performance and code maintainability
for opaques, and requires no change on the user side.

The following lists summarize the unchanged and changed aspects for opaques,
together with a brief discussion justifying this update:

No User-Changes Neeeded
------

- The compiler's treatment regarding opaque types is unchanged.
- Opaques preserve their semantics, even when they are encoded in terms of
nominal types in Dialyzer.
- Documentation for opaques stays hidden.

New Features
------

- Now, doing pattern-matching on opaques will raise a warning without
stopping Dialyzer's analysis. (Previously, doing pattern-matching on opaques
raised an error and caused Dialyzer to stop the analysis, and so Dialyzer
could not catch other errors.)
- Type-checking for nested opaques is fully supported, just like for nominals.

Benefits
------

- **Performance**: Previously, opaque types have at most quartic analysis
time within Dialyzer.  Now they have at most linear analysis time.
- **Maintainability**: Nominal type checking introduces no special cases for
Dialyzer.  All extra type checking functions specifically for opaques can
now be removed.
- **Pattern-matching**: Dialyzer's analysis of opaques does not hard-stop
on pattern-matching violations, which results in a more precise warning,
since the analysis continues.
- **Nested Opaques**: The capacity to check for nested opaques is as useful  
for opaques as for nominals.

Reference Implementation
========================

Current implementation: <https://github.com/lucioleKi/otp/tree/cleanup>

Backward Compatibility
========================

Code that contains no opaque type or does not use Dialyzer has no  change.

Code that contains opaque type(s) and uses Dialyzer may experience changes
mentioned above.

For Other Type-Checkers
----------------------

If other type-checkers do not implement nominal type-checking, they can
treat `-nominal` in the same way as `-type`.

If other type-checkers choose to implement nominal type-checking, they
should implement it in a way that is consistent with this EEP. The purpose
is to ensure that nominal types keep the same semantic, and are type-checked
in the same way across different type-checkers.

[1]: https://flow.org/en/docs/lang/nominal-structural/#in-flow

[TypeScript]: https://michalzalecki.com/nominal-typing-in-typescript/

[2]: https://doc.rust-lang.org/reference/type-system.html

[3]: https://leptonic.solutions/blog/nominal-vs-structural-types/

[4]: https://v2.ocaml.org/manual/manual001.html#start-section

[5]: https://discuss.ocaml.org/t/are-ocaml-records-structurally-typed-or-nominally-typed/12670/4

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
