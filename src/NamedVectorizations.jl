module NamedVectorizations

export NamedVectorization, NV, layout

TYPE_SIZE = Tuple{Vararg{Int}}
TYPE_KEYS = NamedTuple{<:Any,<:Tuple{TYPE_SIZE,Int,Int}}

struct NV{T} <: AbstractVector{T}
    layout::NamedTuple
    vector::Vector{T}
end

vector(nv::NV) = getfield(nv, :vector)
layout(nv::NV) = getfield(nv, :layout)

vectorized(nv::AbstractArray) = vec(nv)
vectorized(nv::Number) = collect(nv)

function NamedVectorization(; elements...)
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

# Check if the passed NVs have pairwise disjoined fields
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

# As Abstract Array
Base.:size(nv::NV) = size(vector(nv))
Base.:getindex(nv::NV, i::Union{Int,UnitRange{Int}}) = vector(nv)[i]
Base.:setindex!(nv::NV, val, i::Int) = vector(nv)[i] = val

# Properties
Base.:propertynames(nv::NV, private::Bool=false) =
    private ? fieldnames(NV) : layout(nv) |> keys
Base.:getproperty(nv::NV, k::Symbol) =
    let (s, start, stop) = layout(nv)[k]
        reshape(vector(nv)[start:stop], s...)
    end

# Broadcasting
struct NVBroadcastStyle <: Broadcast.AbstractArrayStyle{1} end
NVBroadcastStyle(::Val{0}) = NVBroadcastStyle()
NVBroadcastStyle(::Val{1}) = NVBroadcastStyle()
NVBroadcastStyle(::Val{N}) where {N} = Broadcast.DefaultArrayStyle{N}()
Broadcast.BroadcastStyle(::Type{<:NV}) = NVBroadcastStyle()

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
    return similar(init_nv)
end

# Recursively traverse the Broadcasted tree to find an NV
find_NV(args::Tuple) = find_NV(args[1], Base.tail(args))
find_NV(leaf::NV, rest) = leaf, rest
find_NV(leaf::Broadcast.Broadcasted, rest) = find_NV((leaf.args..., rest...))
find_NV(::Any, rest) = find_NV(rest)
find_NV(::Tuple{}) = nothing, ()

# Return the matrix-vector product as an NV only if its lenght is the same as the 
# argument NV
Base.:*(M::AbstractMatrix, nv::NV) =
    let r = M * vector(nv)
        length(r) == length(nv) ? NV{eltype(r)}(layout(nv), r) : r
    end

# Specialize vcat to return a NV with concatenated array and merged layouts if
# all argments NVs have disjoined layouts.
function Base.:vcat(nvs::NV...)
    r = vcat(vector.(nvs)...)
    if disjoined_layouts(nvs...)
        l = 0
        layouts = Vector{NamedTuple}(undef, length(nvs))
        for (i, nv) in enumerate(nvs)
            layouts[i] = NamedTuple(key => (_size, start + l, stop + l) for (key, (_size, start, stop)) in layout(nv) |> pairs)
            l += length(nv)
        end
        return NV{eltype(r)}(merge(layouts...), r)
    else
        return r
    end
end

end # end module NamedVectorizations 
