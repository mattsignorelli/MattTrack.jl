# Functions for float by Dan Abell.
# Modified by Matt to handle eps for different float types.

function sincu(z::AbstractFloat)
  threshold = sqrt(2*eps(z))
  if abs(z) < threshold
    return 1.
  else
    return sin(z) / z
  end
end

function sinhcu(z::AbstractFloat)
  threshold = sqrt(2*eps(z))
  if abs(z) < threshold
    return 1.
  else
    return sinh(z) / z
  end
end