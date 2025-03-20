
abstract type ParameterGroup end

const ParamDict = Dict{Type{<:ParameterGroup}, ParameterGroup}

# Require that Symbol key is equivalent to the parameter group type name:
Base.setindex!(h::ParamDict, v, key) = error("Incorrect key/value t ypes for ParamDict")

function Base.setindex!(h::ParamDict, v::ParameterGroup, key::Type{<:ParameterGroup})
  # 208 ns and 3 allocations
  typeof(v) <: key || error("Key type $key does not match parameter group type $(typeof(v))")
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

mutable struct QuadParams{T <: Number} <: ParameterGroup
  Kn1::T
  tilt::T
  function QuadParams(Kn1, tilt)
    return new{promote_type(typeof(Kn1), typeof(tilt))}(Kn1, tilt)
  end
end

Base.eltype(pg::QuadParams{T}) where {T} = T

mutable struct LengthParams{T <: Number} <: ParameterGroup
  L::T
end

Base.eltype(pg::LengthParams{T}) where {T} = T

function Base.getproperty(ele::LatElement, key::Symbol)
  if key == :pdict
    return getfield(ele, :pdict)
  else
    return getindex(ele.pdict, PARAMETER_MAP[key])
  end
end

function Base.setproperty!(ele::LatElement, key::Symbol, value)
  # Using immutable structs via Accessors.jl: time to update is 452 ns with 7 allocations, irregardless of type change
  # ele.pdict[PARAMETER_MAP[key]] = set(ele.pdict[PARAMETER_MAP[key]], opcompose(PropertyLens(key)), value)

  # With mutable structs, no type change WITH check: time to update is ~65 ns with 3 allocations
  pg = getindex(ele.pdict, PARAMETER_MAP[key])
  # Function barrier for speed
  _setproperty!(ele.pdict, pg, key, value)
end

function _setproperty!(pdict::ParamDict, pg::ParameterGroup, key::Symbol, value)
  T = eltype(pg)
  if typeof(value) == T
    return setfield!(pg, key, value)
  elseif promote_type(typeof(value), T) == T # no promotion necessary
    return setfield!(pg, key, T(value))
  else
    # Use Accessors here bc super convenient for replacing entire mutable type
    pdict[PARAMETER_MAP[key]] = set(pdict[PARAMETER_MAP[key]], opcompose(PropertyLens(key)), value)
  end
end

const PARAMETER_MAP = Dict{Symbol,Type{<:ParameterGroup}}(
  :Kn1 => QuadParams, 
  :tilt => QuadParams,
  :L => LengthParams
)
