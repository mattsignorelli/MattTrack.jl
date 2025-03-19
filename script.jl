using MattTrack, GTPSA, BenchmarkTools

lat = make_lat(10) # Note that we could have parametric types too

bunch = Bunch(1000)

track!(bunch, lat)
