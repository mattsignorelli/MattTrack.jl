mutable struct BMultipole{T<:Number}
  order::Int
  Kn::T       # Normalized field strength
  tilt::T
  function BMultipole(order, Kn, tilt)
    return new{promote_type(typeof(Kn),typeof(tilt))}(order, Kn, tilt)
  end
  function BMultipole{T}(order, Kn, tilt) where {T}
    return new{T}(order, Kn, tilt)
  end
end

# Key == order
# Note we require all multipoles to have same number type
const BMultipoleDict{T} = Dict{Int, BMultipole{T}} where {T<:Number}

# Note the repetitive code - this means we can likely coalesce ParamDict and BMultipoleDict 
# Into some single new Dict type.
function Base.setindex!(h::BMultipoleDict, v::BMultipole, key::Int)
  v.order == key || error("Key $key does not match multipole order $(v.order)")
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

@kwdef struct BMultipoleParams{T<:Number} <: AbstractParams
  bdict::BMultipoleDict{T} = BMultipoleDict{Float64}(1 => BMultipole(1, 0.36, 0.)) # multipole coefficients
end

# Replace will copy the copy + change the type, and if the key is not provided
# then it will add the multipole.
@inline function replace(b::BMultipoleParams{S}, key::Symbol, value) where {S}
  T = promote_type(S, typeof(value))
  ord, sym = BMULTIPOLE_KEY_MAP[key]
  bdict = BMultipoleDict{T}()
  for (order, bm) in b.bdict
    bdict[order] = BMultipole{T}(order, bm.Kn, bm.tilt)
  end
  if !haskey(bdict, ord)
    bdict[ord] = BMultipole{T}(ord, 0, 0)
  end
  setproperty!(bdict[ord], sym, T(value))
  return BMultipoleParams{T}(bdict)
end

function Base.getproperty(bm::BMultipoleParams, key::Symbol)
  if key == :bdict
    return getfield(bm, :bdict)
  else
    order, sym = BMULTIPOLE_KEY_MAP[key]
    return getproperty(getindex(bm.bdict, order), sym)
  end
end

# Also allow array-like indexing of the param struct
function Base.getindex(bm::BMultipoleParams, key)
  return bm.bdict[key]
end

function Base.setproperty!(bm::BMultipoleParams, key::Symbol, value)
  order, sym = BMULTIPOLE_KEY_MAP[key]
  b = getindex(bm.bdict, order)
  return setproperty!(b, sym, value)
end

Base.hasproperty(b::BMultipoleParams, key::Symbol) = haskey(b.bdict, first(BMULTIPOLE_KEY_MAP[key]))

#Base.fieldnames(::Type{<:BMultipoleParams}) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)
#Base.fieldnames(::BMultipoleParams) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)
#Base.propertynames(::Type{<:BMultipoleParams}) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)
#Base.propertynames(::BMultipoleParams) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)

#Base.propertynames(b::BMultipoleParams) = tuple(keys(b.bdict)...)
#BMULTIPOLE_PROPERTIES_MAP[first(keys(b.bdict))] #... for key in keys(BMULTIPOLE_KEY_MAP))..., :bdict)
#Base.getindex.(BMULTIPOLE_PROPERTIES_MAP, keys(b.bdict)...)
#(BMULTIPOLE_PROPERTIES_MAP[key]... for key in keys(BMULTIPOLE_KEY_MAP)..., :bdict)

const BMULTIPOLE_KEY_MAP = Dict{Symbol, Tuple{Int,Symbol}}(
  :Kn0 =>  ( 0, :Kn), 
  :Kn1 =>  ( 1, :Kn),
  :Kn2 =>  ( 2, :Kn),
  :Kn3 =>  ( 3, :Kn),
  :Kn4 =>  ( 4, :Kn),
  :Kn5 =>  ( 5, :Kn),
  :Kn6 =>  ( 6, :Kn),
  :Kn7 =>  ( 7, :Kn),
  :Kn8 =>  ( 8, :Kn),
  :Kn9 =>  ( 9, :Kn),
  :Kn10 => (10, :Kn),
  :Kn11 => (11, :Kn),
  :Kn12 => (12, :Kn),
  :Kn13 => (13, :Kn),
  :Kn14 => (14, :Kn),
  :Kn15 => (15, :Kn),
  :Kn16 => (16, :Kn),
  :Kn17 => (17, :Kn),
  :Kn18 => (18, :Kn),
  :Kn19 => (19, :Kn),
  :Kn20 => (20, :Kn),
  :Kn21 => (21, :Kn), 

  :tilt0 =>  ( 0, :tilt), 
  :tilt1 =>  ( 1, :tilt),
  :tilt2 =>  ( 2, :tilt),
  :tilt3 =>  ( 3, :tilt),
  :tilt4 =>  ( 4, :tilt),
  :tilt5 =>  ( 5, :tilt),
  :tilt6 =>  ( 6, :tilt),
  :tilt7 =>  ( 7, :tilt),
  :tilt8 =>  ( 8, :tilt),
  :tilt9 =>  ( 9, :tilt),
  :tilt10 => (10, :tilt),
  :tilt11 => (11, :tilt),
  :tilt12 => (12, :tilt),
  :tilt13 => (13, :tilt),
  :tilt14 => (14, :tilt),
  :tilt15 => (15, :tilt),
  :tilt16 => (16, :tilt),
  :tilt17 => (17, :tilt),
  :tilt18 => (18, :tilt),
  :tilt19 => (19, :tilt),
  :tilt20 => (20, :tilt),
  :tilt21 => (21, :tilt), 
)

const BMULTIPOLE_PROPERTIES_MAP = Dict{Int, Tuple{Symbol,Symbol}}(
  0 =>  (:Kn0 , :tilt0 ), 
  1 =>  (:Kn1 , :tilt1 ),
  2 =>  (:Kn2 , :tilt2 ),
  3 =>  (:Kn3 , :tilt3 ),
  4 =>  (:Kn4 , :tilt4 ),
  5 =>  (:Kn5 , :tilt5 ),
  6 =>  (:Kn6 , :tilt6 ),
  7 =>  (:Kn7 , :tilt7 ),
  8 =>  (:Kn8 , :tilt8 ),
  9 =>  (:Kn9 , :tilt9 ),
  10 => (:Kn10, :tilt10),
  11 => (:Kn11, :tilt11),
  12 => (:Kn12, :tilt12),
  13 => (:Kn13, :tilt13),
  14 => (:Kn14, :tilt14),
  15 => (:Kn15, :tilt15),
  16 => (:Kn16, :tilt16),
  17 => (:Kn17, :tilt17),
  18 => (:Kn18, :tilt18),
  19 => (:Kn19, :tilt19),
  20 => (:Kn20, :tilt20),
  21 => (:Kn21, :tilt21)
)