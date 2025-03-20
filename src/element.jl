
abstract type Parameters end

# By making the key the parameters type name, we always have a consistent internal definition
const ParamDict = Dict{Type{<:Parameters}, Parameters}
Base.setindex!(h::ParamDict, v, key) = error("Incorrect key/value types for ParamDict")

function Base.setindex!(h::ParamDict, v::Parameters, key::Type{<:Parameters})
  # 208 ns and 3 allocations to check that we set correctly
  typeof(v) <: key || error("Key type $key does not match parameters type $(typeof(v))")
  # The following is copy-pasted directly from Base dict.jl ==========
  index, sh = Base.ht_keyindex2_shorthash!(h, key)

  if index > 0
      h.age += 1
      @inbounds h.keys[index] = key
      @inbounds h.vals[index] = v
  else
      @inbounds Base._setindex!(h, v, key, -index, sh)
  end

  return h
  # ==================================================================
end

struct LatElement
  pdict::ParamDict
end

mutable struct QuadParams{T <: Number} <: Parameters
  Kn1::T
  tilt::T
  function QuadParams(Kn1, tilt)
    return new{promote_type(typeof(Kn1), typeof(tilt))}(Kn1, tilt)
  end
end

Base.eltype(pg::QuadParams{T}) where {T} = T

mutable struct LengthParams{T <: Number} <: Parameters
  L::T
end

Base.eltype(pg::LengthParams{T}) where {T} = T

function Base.getproperty(ele::LatElement, key::Symbol)
  if key == :pdict
    return getfield(ele, :pdict)
  elseif haskey(PARAMS_MAP, key) # To get parameters struct
    return getindex(ele.pdict, PARAMS_MAP[key])
  else  # To get a specific parameter in a parameter struct
    return getindex(ele.pdict, PARAMS_FIELDS_MAP[key])
  end
end

function Base.setproperty!(ele::LatElement, key::Symbol, value)
  # Using immutable structs via Accessors.jl: time to update is 452 ns with 7 allocations, regardless of type change
  # ele.pdict[PARAMS_FIELDS_MAP[key]] = set(ele.pdict[PARAMS_FIELDS_MAP[key]], opcompose(PropertyLens(key)), value)

  # With mutable structs time to update is ~65 ns with 3 allocations
  if haskey(PARAMS_MAP, key)
    setindex!(ele.pdict, value, PARAMS_MAP[key])
  else
    pg = getindex(ele.pdict, PARAMS_FIELDS_MAP[key])
    # Function barrier for speed
    _setproperty!(ele.pdict, pg, key, value)
  end
end

function _setproperty!(pdict::ParamDict, pg::Parameters, key::Symbol, value)
  T = eltype(pg)
  if typeof(value) == T # no promotion necessary
    return setfield!(pg, key, value)
  elseif promote_type(typeof(value), T) == T  # promote
    return setfield!(pg, key, T(value))
  else
    # Use Accessors here bc super convenient for replacing entire (even mutable) type
    return pdict[PARAMS_FIELDS_MAP[key]] = set(pdict[PARAMS_FIELDS_MAP[key]], opcompose(PropertyLens(key)), value)
  end
end

const PARAMS_FIELDS_MAP = Dict{Symbol,Type{<:Parameters}}(
  :Kn1 => QuadParams, 
  :tilt => QuadParams,
  :L => LengthParams
)

const PARAMS_MAP = Dict{Symbol,Type{<:Parameters}}(
  :QuadParams => QuadParams,
  :LengthParams => LengthParams
)
