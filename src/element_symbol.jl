# T can be TPSA or regular numbers or Duals etc
abstract type ParameterGroup end

struct TrackParams end

struct QuadParams{T <: Number} <: ParameterGroup
  Kn1::T
  tilt::T
end

struct LengthParams{T <: Number} <: ParameterGroup
  L::T
end

const ParamDict = Dict{Symbol, ParameterGroup}

# Require that Symbol key is equivalent to the parameter group type name:
#Base.setindex!(h::ParamDict, v, key) = error("Key does not match parameter group type")

function Base.setindex!(h::ParamDict, v::ParameterGroup, key::Symbol)
  # THIS CHECK IS SLOW! 11 allocations and 312 ns for set
  Symbol(Base.typename(typeof(v)).wrapper) == key || error("Key does not match parameter group type")
  index, sh = Base.ht_keyindex2_shorthash!(h, key)

  if index > 0
      h.age += 1
      @inbounds h.keys[index] = key
      @inbounds h.vals[index] = v
  else
      @inbounds Base._setindex!(h, v, key, -index, sh)
  end

  return h
end

#=

struct LatElement
  params::Di
end


#=
@kwdef mutable struct LatticeElement
  pdict::Dict{Symbol, ParameterGroup} = Dict(:QuadParams=>QuadParams(0.36, pi/4), :LengthParams=>LengthParams(0.5))
end
=#
function Base.getproperty(ele::LatticeElement, key::Symbol)
  if key == :tracking_method
    return getfield(ele, :tracking_method)
  elseif key == :pdict
    return getfield(ele, :pdict)
  else
    return getindex(ele.pdict, PARAMETER_MAP[key])
    #return getfield(pg, key)
    #return getindex(ele.pdict, PARAMETER_MAP[key])
  end
end

function Base.setproperty!(ele::LatticeElement, key::Symbol, value)
  if key == :tracking_method
    setfield!(ele, :tracking_method, value)
  elseif key == :pdict
    setfield!(ele, :pdict, value)
  else
    pg = getindex(ele.pdict, PARAMETER_MAP[key])
    setfield!(pg, key, value)
  end
end

const PARAMETER_MAP = Dict{Symbol,Symbol}(
  :Kn1 => :QuadParams, 
  :tilt => :QuadParams,
  :L => :LengthParams
)
=#