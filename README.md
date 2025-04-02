# NamedVectorizations.jl

A Named Vectorization (`NV`) is a [`Vector`](https://docs.julialang.org/en/v1/base/arrays/#Base.Vector-Tuple%7BUndefInitializer,%20Any%7D)s whose chunks represent the flattening of some defined [`Array`](https://docs.julialang.org/en/v1/base/arrays/#Core.Array-Tuple{UndefInitializer,%20Any})s or [`Number`](https://docs.julialang.org/en/v1/base/numbers/)s, which remain accessable as properties. It's an expressive implementation of the [vectorization operation](https://en.wikipedia.org/wiki/Vectorization_(mathematics)), which is commonly used in mathematical modelling, system theory, and optimization. 

## Broadcasting rules

`NV` is a subtype of [`AbstractVector`](https://docs.julialang.org/en/v1/base/arrays/#Base.AbstractVector), hence the usual broadcasting rules apply. For some operations and arguments, the *layout* of `NV` is preserved as follows

| Description | Operation | Conditions | 
| ----------- | --------- | ---------- |
| Unary broadcasting | `f.(x::NV)` | None |
| Binary broadcasting (Arrays) | `f.(x::NV, y::AbstractArray)` | `ndims(y) <= 1` |
| Binary broadcasting (NVs) | `f.(x::NV, y::NV)` | `layout(x) == layout(y)` |
