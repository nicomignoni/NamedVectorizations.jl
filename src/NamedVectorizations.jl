module NamedVectorizations

export NV, vector, layout

"""
    NV{T}(layout, vector)

The named vectorization core struct. 

# Fields
- `vector::Vector`: the Vector representing the concatenation of the vectorized Array and 
Scalar elements. 
- `layout::NamedTuple`: it defines the position and dimension of the Arrays comprising the 
NV with respect to the vectorized representation. Each key-value pair is 
`(array_name => (array_size, start, stop))` where `start` and `stop` bound the vector chunk 
containing the vectorized Array. 
"""
struct NV{T} <: AbstractVector{T}
    # TODO figure out why Int instead of Any doesn't work.
    layout::NamedTuple # {<:Any, <:Tuple{Tuple, Any, Any}} 
    vector::Vector{T}
end

"""
    vector(nv::NV) 

Alias for `getfield(nv, :vector)`.
"""
vector(nv::NV) = getfield(nv, :vector)

"""
    layout(nv::NV)

Alias for `getfield(nv, :layout)`.
"""
layout(nv::NV) = getfield(nv, :layout)

# Handles the vectorization of the parameters passed to the NV constructor.
vectorized(x::AbstractArray) = vec(x)
vectorized(x::Any) = collect(x)

"""
    NV(; elements...)

NVs constructor. 
"""
function NV(; elements...)
    vector = vcat((vectorized(element) for (_, element) in elements)...)
    layout = Vector{NamedTuple}(undef, length(elements))

    stop = 0
    for (i, (key, element)) in enumerate(elements)
        start = stop + 1
        stop = start + length(element) - 1

        layout[i] = (key => (size(element), start, stop),)
    end

    # kwargs cannot have the same layout, so `merge` is safe. 
    return NV{eltype(vector)}(merge(layout...), vector)
end

# Printing
size_format(s::Tuple{Vararg{Int}}) = "Array $(join(s, 'x'))"
size_format(s::Tuple{Int,Int}) = "Matrix $(join(s, 'x'))"
size_format(s::Tuple{Int}) = "$(s[1])-element Vector"
size_format(::Tuple{}) = "Number"

interval_format(start::Int, stop::Int) = start == stop ? "[$start]" : "[$start-$stop]"
tree_char(i::Int, depth::Int) = i == depth ? "└" : "├"

function Base.showarg(io::IO, nv::NV, toplevel)
    depth = layout(nv) |> length
    l = ["$(tree_char(i, depth)) $k: $(size_format(s)), $(interval_format(start, stop))"
         for (i, (k, (s, start, stop))) in layout(nv) |> pairs |> enumerate]
    print(io, "NV{$(eltype(nv))} with layout: \n$(join(l, '\n'))")
end

# Checks if the passed NVs have pairwise disjoined layouts: it returns `true` 
# only if no pair of NVs has layouts with one (or more) common keys. 
function disjoined_layouts(nvs::NV...)
    seen_symbols = Set{Symbol}()
    for nv in nvs, sym in layout(nv) |> keys
        if sym in seen_symbols
            return false
        else
            push!(seen_symbols, sym)
        end
    end
    return true
end

Base.:similar(nv::NV) =
    let T = eltype(nv)
        NV{T}(layout(nv), Vector{T}(undef, length(nv)))
    end

Base.:similar(nv::NV, T::Type) = NV{T}(layout(nv), Vector{T}(undef, length(nv)))
Base.:similar(nv::NV, s::Dims) =
    let T = eltype(nv)
        s == size(nv) ? NV{T}(layout(nv), Vector{T}(undef, s)) : Array{T}(undef, s)
    end
Base.:similar(nv::NV, T::Type, s::Dims) =
    s == size(nv) ? NV{T}(layout(nv), Vector{T}(undef, s)) : Array{T}(undef, s)

# As Abstract Array
Base.:size(nv::NV) = size(vector(nv))
Base.:getindex(nv::NV, i::Union{Int,UnitRange{Int}}) = vector(nv)[i]
Base.:setindex!(nv::NV, val, i::Int) = vector(nv)[i] = val

# Properties

# Returns the a vector chunk properly reshaped based on the size `s`.
deliver_chunk(v::SubArray, ::Tuple{}) = v[]
deliver_chunk(v::SubArray, ::Tuple{Int}) = v
deliver_chunk(v::SubArray, s::Tuple{Vararg{Int}}) = reshape(v, s...)

Base.:propertynames(nv::NV, private::Bool=false) =
    private ? fieldnames(NV) : layout(nv) |> keys
Base.:getproperty(nv::NV, k::Symbol) =
    let (s, start, stop) = layout(nv)[k]
        @views deliver_chunk(vector(nv)[start:stop], s)
    end
Base.:setproperty!(nv::NV, k::Symbol, val) =
    let (_, start, stop) = layout(nv)[k]
        vector(nv)[start:stop] = vectorized(val)
    end

# Broadcasting
struct NVBroadcastStyle <: Broadcast.AbstractArrayStyle{1} end
NVBroadcastStyle(::Val{0}) = NVBroadcastStyle()
NVBroadcastStyle(::Val{1}) = NVBroadcastStyle()
NVBroadcastStyle(::Val{N}) where {N} = Broadcast.DefaultArrayStyle{N}()
Broadcast.BroadcastStyle(::Type{<:NV}) = NVBroadcastStyle()

# If all the NVs in the broadcasting operation have the same layout, it returns an 
# uninitialized NV with the same layout. Otherwise, it falls back to a Vector of the 
# correct length.
function Base.:similar(bc::Broadcast.Broadcasted{NVBroadcastStyle}, T::Type)
    init_nv, rest = find_NV(bc.args)
    while !isempty(rest)
        nv, rest = find_NV(rest)
        if nv === nothing
            break
        elseif layout(nv) != layout(init_nv)
            return Vector{T}(undef, length(init_nv))
        end
    end
    return similar(init_nv, T)
end

# Recursively traverse the Broadcasted tree to find an NV.
find_NV(args::Tuple) = find_NV(args[1], Base.tail(args))
find_NV(leaf::NV, rest::Tuple) = leaf, rest
find_NV(leaf::Broadcast.Broadcasted, rest::Tuple) = find_NV((leaf.args..., rest...))
find_NV(::Any, rest::Tuple) = find_NV(rest)
find_NV(::Tuple{}) = nothing, ()

# Operations

# Extends the matrix-vector product for NVs. Returns the matrix-vector product as an NV only 
# if its lenght is the same as the argument NV.
Base.:*(M::AbstractMatrix, nv::NV) =
    let r = M * vector(nv)
        length(r) == length(nv) ? NV{eltype(r)}(layout(nv), r) : r
    end

# Specializes vcat to return:
#  - a NV with concatenated array and merged layouts if all argments NVs have disjoined layouts
#  - the concatanation of the vectors comprising the NVs otherwise
function Base.:vcat(nvs::NV...)
    r = vcat(vector.(nvs)...)
    if disjoined_layouts(nvs...)
        l = 0
        layouts = Vector{NamedTuple}(undef, length(nvs))
        for (i, nv) in enumerate(nvs)
            layouts[i] = NamedTuple(
                key => (_size, start + l, stop + l) for
                (key, (_size, start, stop)) in layout(nv) |> pairs
            )
            l += length(nv)
        end
        return NV{eltype(r)}(merge(layouts...), r)
    else
        return r
    end
end

end # end module NamedVectorizations 
