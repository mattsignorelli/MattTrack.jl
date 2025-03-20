using MattTrack, BenchmarkTools
using DifferentiationInterface
using GTPSA, ForwardDiff, ReverseDiff

lat = make_lat(10) # Note that we could have parametric types too

bunch = Bunch(1000)

@btime track!($bunch, $lat)

# Now let's do TPSA:
const D = Descriptor(4, 1)
Δx = @vars(D)
x0 = rand(4)

# See structure of arrays (SoA) layout:
m = Bunch([x0[1]+Δx[1]], [x0[2]+Δx[2]], [x0[3]+Δx[3]], [x0[4]+Δx[4]])
track!(m, lat)

# Convert SoA to single particle array of [x, px, y, py]:
tp = [m.x[1], m.px[1], m.y[1], m.py[1]]
J_GTPSA = GTPSA.jacobian(tp)

# Now let's do it generically using DifferentiationInterface.jl
# We need a single function to differentiate, so let's define a helper
# which takes in [x, px, y, py], converts to SoA, tracks, and then 
# converts back to [x, px, y, py]:
function track_particle(z, lat)
  b = Bunch([z[1]], [z[2]], [z[3]], [z[4]])
  track!(b, lat)
  return [b.x[1], b.px[1], b.y[1], b.py[1]]
end

# Now we can easily use DifferentiationInterface to compute the Jacobian
# AutoGTPSA is the "backend" type to specify for GTPSA:
J_GTPSA_DI = jacobian(z->track_particle(z, lat), AutoGTPSA(), x0)

J_GTPSA_DI == J_GTPSA # true

# Now can easily use ForwardDiff or ReverseDiff:
J_FD = jacobian(z->track_particle(z, lat), AutoForwardDiff(), x0)
J_RD = jacobian(z->track_particle(z, lat), AutoReverseDiff(), x0)

J_FD == J_GTPSA # true
norm(J_RD - J_GTPSA) < 1e-13 # true


# Another thing to consider is how to handle parametric lattice.
# This will may be a bit of a challenge as the "helper" function we defined 
# above will also need to make the lattice parametric.


# Let's define a function to calculate the jacobian of the map including 
# one knob which controls both quadrupoles:
# z[5] corresponds to Kn1
function track_particle_lat_parametric(z, lat)
  # Should first set the lattice to have Kn1:
  for ele in lat
    if ele.params.Kn1 > 0
      ele.params = Params(promote(z[5], ele.params.L)...)
    elseif ele.params.Kn1 < 0
      ele.params = Params(promote(-z[5], ele.params.L)...)
    end
  end

  # now can track as usual:
  b = Bunch([z[1]], [z[2]], [z[3]], [z[4]])
  track!(b, lat)
  return [b.x[1], b.px[1], b.y[1], b.py[1]]
end

# Note that for SciBmad, these functions as defined above should have all 
# temporaries pulled out of it, so that for each iteration/computation of 
# derivatives there is no remaking/reallocations any vectors.

J_GTPSA_para = jacobian(z->track_particle_lat_parametric(z, lat), AutoGTPSA(), [x0..., 0.36])

# After running the above, the lattice contain has TPSA types as params, 
# which may not be convertible to Duals in other packages, so let's start fresh
lat = make_lat(10)
J_FD_para = jacobian(z->track_particle_lat_parametric(z, lat), AutoForwardDiff(), [x0..., 0.36])
# Likewise:
lat = make_lat(10) 
J_RD_para = jacobian(z->track_particle_lat_parametric(z, lat), AutoReverseDiff(), [x0..., 0.36])