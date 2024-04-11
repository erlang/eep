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
`feet()` are equivalent in a structural type system, because they have 
the same structure.  The two types can be used interchangeably.  Neither 
of them differ from the basic type `integer()`. 

    -type meter() :: integer().
    -type feet() :: integer().

Nominal typing is an alternative type system, where two types are equivalent 
if and only if they are declared with the same type name.  If the example 
above is in a nominal type system, `meter()` and `feet()` are no longer 
compatible because they have different names.  Whenever a function expects 
type `meter()`, passing in type `feet()` would result in an error.  Nominal 
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
    -nominal feet() :: integer().

    % Constructor for nominal types
    -spec meter_ctor(integer()) -> meter().
    meter_ctor(X) -> X.

    % Function that has its input and/or output as nominal types
    -spec meter_to_feet(meter()) -> feet().
    meter_to_feet(X) -> X * 3.

Nominal types are declared and used in the same way as other user-defined 
types.  The compiler recognizes the syntax, but does not perform extra 
type-checking.  Type checking for nominal types is done in Dialyzer.

According to nominal type-checking rules, if two nominal types have different 
names, and one is not nested in the other, then they are not compatible.  
For instance, if we continue from the example above:

    -spec foo() -> feet().
    foo() -> meter_ctor(24). 
    % Output type: meter(). 
    % Expected type: feet().
    % Result: Dialyzer error.

Dialyzer returns the following error for the function `foo()`: 
    
    Invalid type specification for function example:foo/0.
    The success typing is example:foo
          () ->
             nominal({'example', 'meter', 0, 'transparent'}, integer())
    But the spec is example:foo
          () -> feet()
     The return types do not overlap
    
On the other hand, nominal type-checking does not force the user to wrap or 
annotate values as nominal types. In the following example, Dialyzer does 
not return any error for the function `bar()`. The spec for `meter_to_feet()` 
expects a `meter()` type as input.  Passing in a `integer()` type is allowed, 
because `meter()` is defined to have type `integer()`.  Only if the input 
is of a different basic type, for example `atom()`, Dialyzer will reject it.

    -spec bar() -> feet().
    bar() -> meter_to_feet(24). 
    % Input type: integer(). 
    % Expected type: meter().
    % Result: No error.

When a nominal type is expected, passing in a type with the same structure 
is also allowed.  In the following example, Dialyzer does not return any 
error for the function `qaz()`.  The spec for `meter_ctor()` expects a 
`integer()` type as input. Passing in a `meter()` type is allowed, because 
`meter()` is defined to have type `integer()`.  Similarly, passing in a 
type `feet()` is also allowed when `integer()` is expected.

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


No User-Changes Neeeded:
------

- The compiler's treatment regarding opaque types is unchanged.
- Opaques preserve their semantics, even when they are encoded in terms of 
nominal types in Dialyzer.
- Documentation for opaques stays hidden. 


New Features:
------

- Now, doing pattern-matching on opaques will raise a warning without 
stopping Dialyzer's analysis. (Previously, doing pattern-matching on opaques 
raised an error and caused Dialyzer to stop the analysis, and so Dialyzer 
could not catch other errors.)
- Type-checking for nested opaques is fully supported, just like for nominals.


Benefits:
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


Backward compatibility
========================
Code that contains no opaque type or does not use Dialyzer has no change.

Code that contains opaque type(s) and uses Dialyzer may experience changes 
mentioned above.


[1]: https://flow.org/en/docs/lang/nominal-structural/#in-flow

[TypeScript]: https://michalzalecki.com/nominal-typing-in-typescript/

[NominalTypeScript]: https://github.com/Microsoft/TypeScript/issues/202

[2]: https://doc.rust-lang.org/reference/type-system.html

[3]: https://leptonic.solutions/blog/nominal-vs-structural-types/

[4]: https://v2.ocaml.org/manual/manual001.html#start-section

[5]: https://discuss.ocaml.org/t/are-ocaml-records-structurally-typed-or-nominally-typed/12670/4

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
