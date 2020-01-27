mutable struct Priors
  delta0
  delta1
  sig2
  W
  eta0
  eta1
  v
  H
  alpha
  eps
end

# NOTE: Uses Gamma(shape, scale) parameterization.

function Priors(;K::Int, L::Dict{Bool, Int}, use_stickbreak::Bool=false)
  if use_stickbreak
    v_prior = a -> Beta(a, oftype(a, 1))
  else
    v_prior = a -> Beta(a / K, oftype(a, 1))
  end

  return Priors(Gamma(1, 1),# delta0
                Gamma(1, 1), # delta1
                LogNormal(-1, .1), # sig2
                # Gamma(2, .1), # sig2
                Dirichlet(ones(K) / K), # W
                Dirichlet(ones(L[0]) / L[0]), # eta0
                Dirichlet(ones(L[1]) / L[1]), # eta1
                v_prior, # v
                Uniform(0, 1), # H
                Gamma(0.1, 10.0), # alpha
                Beta(1, 99)) # eps
end
