# NamedVectorizations.jl

*Vectorization in Julia, made convenient.*

## Installation
```julia
] add https://github.com/nicomignoni/NamedVectorizations.jl.git
```

## Quickstart
A Named Vectorization (`NV`) is a [`Vector`](https://docs.julialang.org/en/v1/base/arrays/#Base.Vector-Tuple%7BUndefInitializer,%20Any%7D) whose chunks represent the flattening of some defined [`Array`](https://docs.julialang.org/en/v1/base/arrays/#Core.Array-Tuple{UndefInitializer,%20Any}) or [`Number`](https://docs.julialang.org/en/v1/base/numbers/), which remain accessible as property. It's an expressive implementation of the [vectorization operation](https://en.wikipedia.org/wiki/Vectorization_(mathematics)), which is commonly used in mathematical modelling, system theory, and optimization. 

```@example QUICKSTART
using NamedVectorizations

A = [4 5; 2 1]
b = [9; -2]
c = 7

nv = NV(A=A, b=b, c=c)
nothing #hide
```

```@repl QUICKSTART
nv
```

`NV` vectorizes the passed parameters and stacks them, just like the usual vectorization.

```@repl QUICKSTART
nv == [vec(A); b; c]
```

However, you can still easily access the initial `Array` and `Number` constituting the `NV` as [`views`](https://docs.julialang.org/en/v1/base/arrays/#Views-(SubArrays-and-other-view-types)). 

```@repl QUICKSTART
nv.A
nv.b
nv.c
```

An `NV` is characterized by a `vector`, the internal representation of the vectorization
```@repl QUICKSTART 
vector(nv)
```

and a `layout`, i.e., how the `Arrays` and `Numbers` are arranged in the `NV`.
```@repl QUICKSTART
layout(nv)
```
Specifically, each `Symbol` of the `NamedTuple` points to a `Tuple` (`size`, `start`, `end`), where `size` is the size of the `Array` to be vectorized (`()` in case of a `Number`), while `start` and `end` indicate the slice of `vector(nv)` where the vectorized `Array` is placed. 



