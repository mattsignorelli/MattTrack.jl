module MattTrack
export MattStandard, Params, LatticeElement, Bunch, make_lat, track!

using GTPSA
import GTPSA: sincu, sinhcu

include("utils.jl")

abstract type TrackingMethod end
struct MattStandard <: TrackingMethod end

# T can be TPSA or regular numbers or Duals etc
struct Params{T <: Number}
  Kn1::T
  L::T
end

mutable struct LatticeElement
  params::Params
  tracking_method::TrackingMethod
end

struct Bunch{T <: Number}
  x::Vector{T}
  px::Vector{T}
  y::Vector{T}
  py::Vector{T}
end

function Bunch(n::Integer, ::Type{T}=Float64) where T <: Number
  return Bunch(rand(T, n), rand(T, n), rand(T, n), rand(T, n))
end

function make_lat(n::Integer=1; Kn1=0.36, L_quad=0.5, L_drift=1.)
  function make_matt_ele(Kn1, L)
    return LatticeElement(Params(Kn1, L), MattStandard())
  end

  fodo = [make_matt_ele(Kn1, L_quad), make_matt_ele(0., L_drift),
          make_matt_ele(-Kn1, L_quad), make_matt_ele(0., L_drift)]
  lat = repeat(fodo, n)
  return lat
end

function track!(bunch::Bunch, lat::Vector{<:LatticeElement})
  tmp = zero(bunch.x)
  for ele in lat
    track!(bunch, ele, tmp)
  end
  return bunch
end

function track!(bunch::Bunch, ele::LatticeElement, tmp=nothing)
  return track!(bunch, ele.tracking_method, ele.params, tmp) # Function barrier technique
end

function track!(bunch::Bunch, ::MattStandard, params::Params, tmp=nothing)
  L = params.L
  Kn1 = params.Kn1

  if abs(Kn1 - 0.0) < eps(Kn1) # Drift
    @FastGTPSA! begin
      @. bunch.x += bunch.px * L
      @. bunch.y += bunch.py * L
    end
  else
    if Kn1 >= 0
      fq = bunch.x
      fp = bunch.px
      dq = bunch.y
      dp = bunch.py
      sqrtk = sqrt(Kn1)
    else
      fq = bunch.y
      fp = bunch.py
      dq = bunch.x
      dp = bunch.px
      sqrtk = sqrt(-Kn1)
    end

    # One temporary array, for 1000 Floats is 3 allocations on Julia v1.11
    
    if isnothing(tmp)
      tmp = zero(fq)
    end
    #tmp = (eltype(fq)).(fq)

    # copy and copy! behavior by GTPSA may be modified in future (weirdness 
    # because TPS is mutable). For now 0 + with FastGTPSA! is workaround.
    @FastGTPSA! begin
      @. tmp = 0 + fq
      @. fq = cos(sqrtk*L)*fq + L*sincu(sqrtk*L)*fp
      @. fp = -sqrtk*sin(sqrtk*L)*tmp + cos(sqrtk*L)*fp
      @. tmp = 0 + dq
      @. dq = cosh(sqrtk*L)*dq + L*sinhcu(sqrtk*L)*dp
      @. dp = sqrtk*sinh(sqrtk*L)*tmp + cosh(sqrtk*L)*dp
    end

  end
  return bunch
end



end
