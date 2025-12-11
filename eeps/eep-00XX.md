    Author: José Valim <jose(dot)valim(at)dashbit(dot)co>
    Status: Active
    Type: Process
    Created: 09-Dec-2025
    Post-History:
****
EEP XX: Partially applied functions
----

Abstract
========

This EEP proposes an alternative to "MFArgs" (Module-Function-Arguments):
three-element tuples where the first element is a module, the second is
a function name, and the third is a list of arguments. The proposed
alternative preserves the desired properties of MFArgs while being more
ergonomic and with none of MFArgs limitations.

Rationale
=========

Today, the use of MFArgs are pervasive in Erlang. Generally speaking,
an API accepts MFArgs either as tuples or as three distinct arguments.
MFArgs can be invoked as-is but quite often they have additional arguments
prepended, as shown below:

```erlang
{Mod, Fun, Args} = MFArgs
apply(Mod, Fun, [SomeValue | Args]).
```

One of the main reasons MFArgs exist is because anonymous functions
which close over an existing environment cannot be serialized across
nodes nor be persisted to disk, so when dealing with distribution,
disk persistence, or hot code upgrades, you must carefully stick with
MFArgs. Similarly, configuration files do not support anonymous
functions, and MFArgs are the main option.

Due to those limitations, many functions in Erlang/OTP and also in
libraries need to provide two APIs, one that accepts function types
and another for MFArgs.

Despite their wide spread use, MFArgs come with several downsides:

1. It is unclear which arity of the function will actually be invoked.
   For example, `{some_mod, some_fun, [Arg1, Arg2]}` may have an
   argument prepended when invoked, so what is invoked in practice
   is `fun some_mod:some_fun/3`;

2. Due to the above, they don't play well with `xref` or "go to
   definition" used by editors;

3. They are hard to evolve. Imagine you define an API that accepts
   `{some_mod, some_fun, [Arg1, Arg2]}` and you prepend one argument.
   In the future, users request for another agument to be prepended.
   Using anonymous functions, you could use `is_function(Fun, Arity)`
   to determine how many arguments are expected. With MFArgs, you can
   use `erlang:function_exported/3`, but it may have false positives
   (as in a higher arity function may exist for other purposes);

4. They cause duplication in APIs, as APIs need to accept both `Fun`
   and `MFArgs` as arguments;

5. As we attempt to statically type Erlang programs, MFArgs offer
   limited opportunities for static verification, which either
   becomes the source of dynamism (so errors that could be caught
   statically must now be handled at runtime) or leads to false
   positives (requiring developers to rewrite their code);

Solution
========

Erlang must provide a contruct for partially applied functions.
Partially applied functions use the `fun Mod:Fun(...Args)` notation,
where arguments can also be placeholders given by the `_` variable.

We will break down the syntax in the following section. For now,
let's see an example:

    1> Fun = fun maps:get(username, _).
    2> Fun(#{username => "Joe"}).
    "Joe"

The above is equivalent to:

    1> Fun = fun(X) -> maps:get(username, X) end.
    2> Fun(#{username => "Joe"}).
    "Joe"

While the proposed notation does provide syntactical affordances,
the most important aspect is that the function preserves its remote
name and arguments within the runtime. This means the partially
applied function can be passed across nodes or written to disk,
even if the module that defines the function is gone.

Furthermore, partially applied functions can replace `MFArgs`,
removing all ambiguity about its behaviour. For example, imagine
the configuration below:

```erlang
{some_config, {some_mod, some_fun, [answer, 42]}}.
```

If `some_config` is invoked with an additional argument, such
argument is not specified in the configuration definition itself,
therefore it is unclear which arity of `some_mod:some_fun` will
be invoked. But with partially applied functions, the number of
arguments is always clear, "go to definition" works, as config
files and static typing:

```erlang
{some_config, fun some_mod:some_fun(_, answer, 42)}.
```

In practice, they solve all the downsides of `MFArgs` listed above:

1. The arity is always clear;

2. `xref` or "go to definition" can be unambiguously implemented;

3. It is possible to handle different arities via
   `is_function(Fun, Arity)` checks;

4. There is no longer a need for MFArgs, functions are all you need;

5. They can be statically checked;

Syntax Specification
====================

The syntax of partially applied functions will be:

```erlang
fun Fun(...Args)
fun Mod:Fun(...Args)
```

Where `Args` can be zero, one, or many arguments. Arguments
must be either literals or bound variables. We have seen
literal examples above, but the arguments may also be variables:

```erlang
Key = get_key().
Fun = fun maps:get(Key, _).
```

The `_` variable denotes placeholders, which are arguments
that have not yet been provided (the use of `_` is a proposal,
the exact notation can be changed). The number of placeholders
dictate the arity of the function and they are provided in order.
For example:

```erlang
fun hello(_, world, _)
```

is equivalent to:

```erlang
fun(X, Y) -> hello(X, world, Y) end
```

Note Erlang will guarantee the applied arguments are either literals
or bound variables, ensuring the functions are indeed persistent across
nodes/modules. This is important because the role of this feature goes
beyond syntax sugar: it allows Erlang developers to glance at the code
and, as long as it uses `fun Mod:Fun/Arity` or `fun Mod:Fun(...Args)`,
they know they can be persisted. This information could also be used
by static analyzers and other features to lint code around distribution
properties.

It should also be possible to partially apply a module/function pair
given by bound variables:

```erlang
fun Mod:Fun(username, _)
```

However, it is not possible to partially apply an unknown local function
(mirror the fact that `fun Fun/0` is not valid today):

```erlang
fun Fun(username, _) % will fail to compile
```

It is also possible to apply all arguments, meaning a zero-arity function
is returned:

```erlang
fun Mod:Fun(arg1, arg2, arg3)
```

Visual cluttering
-----------------

Given Erlang also supports named functions, the differences
between named functions, partially applied, and regular
`Function/Arity` may be too small:

```erlang
foo(Y) -> Y-1.
bar(X) ->
    F1 = fun Foo(X) -> X+1 end, % Arity 1
    F2 = fun foo(X),            % Arity 0
    F3 = fun foo/1,             % Arity 1
    {F1(X), F2(), F3(X)}.
```

In case this is deemed a restriction, different options could be
considered:

* Require all partially applied functions to have at least one `_`,
  forbidding `fun foo(X)` or `fun some_mod:some_fun(Args)`. This does
  add a syntactical annoyance but it does not remove any capability
  as any function without placeholder can be written as a zero-arity
  function;
  
* Only allow remote partially applied functions, so `fun foo(_, ok)`
  is invalid, but `fun some_mod:foo(_, ok)` is accepted. Unfortunately,
  this may lead to developers doing external calls when a local call
  would suffice;

* Require partially applied functions to explicit list the arity too,
  hence `fun foo(X)` has to be written as: `fun foo(X)/0`.
  `fun maps:get(username, _)` as `fun maps:get(username, _)/1`.
  If the version with arity is preferred, then the `fun` prefix could
  also be dropped, if desired, as there is no ambiguity;

Alternative Solutions
=====================

The solution above chose to extend the existing `fun` syntax and use
`_` as a placeholder. Those exact details can be changed accordingly.

Note this EEP focuses on language changes, rather than runtime changes,
because whatever solution is chosen must support configuration files,
which are limited in terms of code execution. This means an API that
worked exclusively at runtime would not tackle all of the use cases
handled by MFArgs.

With that in mind, we discuss some alternatives below.

`{Fun, Args}` Pairs
-------------------

One alternative is to support `{fun some_mod:some_fun/3, [Arg1, Arg2]}`.
This does improve a few things, as it makes the arity clear and "go to
definition" also works, but it still requires duplication across APIs,
as they need to support both regular functions and `{Fun, Args}` pairs.

`{Fun, Args}` would likely allow us to type check the return type, but
the argument types could only be partially validated.

Additional Data Types
---------------------

Additional data types could also be introduced, for example, a
"serializable function" record which would be internally represented as
a MFArgs. Its major advantage is that it would not need changes to the
runtime and those working on type systems could type check these new
records accordingly. However, they would still force library developers
to define duplicate APIs that accept both serializable and regular
functions.

Of course, we could change `is_function/2`, `apply/2`, and friends to
support this additional data type but, if we are ultimately changing
the Erlang runtime, I'd argue it is simpler and more productive to add
the serialization properties to functions, as done in this proposal,
than adding a new construct.

Cuts from erlando
-----------------

The [`erlando`](https://github.com/rabbitmq/erlando) project offered
the ability to partially apply functions (and also data structures).

In particular, `erlando` does not require the `fun` prefix, so one can
write:

```erlang
maps:get(username, _)
```

The lack of a prefix makes it harder to spot when a function is created
and also leads to visual ambiguity, such as in the code below:

```erlang
list_to_binary([1, 2, math:pow(2, _)])
```

Their documentation clarifies that it is always shallow (hence it applies
to `math:pow/2`).

`erlando` also allows expressions of arbitrary complexity as argument:

```erlang
maps:get(get_key_from(lists:flatten(Arg)), _)
```

This is intentionally disallowed in this proposal because one of the primary
goals of this proposal is to offer a clear syntactical affordance for functions
that are persistent across nodes.

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
