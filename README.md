# NamedVectorizations.jl

A Named Vectorization (`NV`) is a [`Vector`](https://docs.julialang.org/en/v1/base/arrays/#Base.Vector-Tuple%7BUndefInitializer,%20Any%7D) whose chunks represent the flattening of some defined [`Array`](https://docs.julialang.org/en/v1/base/arrays/#Core.Array-Tuple{UndefInitializer,%20Any}) or [`Number`](https://docs.julialang.org/en/v1/base/numbers/), which remain accessible as property. It's an expressive implementation of the [vectorization operation](https://en.wikipedia.org/wiki/Vectorization_(mathematics)), which is commonly used in mathematical modelling, system theory, and optimization. 

```julia
using NamedVectorizations

A = [4 5; 2 1]
b = [9; -2]
c = 7

nv = NamedVectorization(A=A, b=b, c=c)

julia> nv
7-element NV{Int64} with layout:
 - A: Matrix 2x2, [1-4]
 - b: 2-element Vector, [5-6]
 - c: Number, [7]:
  4
  2
  5
  1
  9
 -2
 10
```

Apart from the `size` and elements' type, an `NV` is characterized by a `layout`, i.e., how the `Arrays` and `Numbers` are arranged in the `NV`. 

`NV` vectorizes the passed parameters and stacks them, just like the usual vectorization

```julia
julia> nv == [vec(A); b; c]
true
```

However, you can still easily access the initial `Array` and `Number` constituting the `NV` as [`views`](https://docs.julialang.org/en/v1/base/arrays/#Views-(SubArrays-and-other-view-types)). 

```julia
julia> nv.A
2×2 reshape(view(::Vector{Int64}, 1:4), 2, 2) with eltype Int64:
 4  5
 2  1

julia> nv.b
2-element view(::Vector{Int64}, 5:6) with eltype Int64:
  9
 -2

julia> nv.c
7
```
