function arrMatTo3dArr(x)
  @assert all(length.(x) .== length(x[1,1]))
  K = length(x[1,1])
  return [x[i,j][k] for i in 1:size(x,1), j in 1:size(x,2), k in 1:K]
end

@namedargs mutable struct Constants
  alpha_prior::Gamma # alpha ~ Gamma(shape, scale)
  delta_prior::Dict{Int, Truncated{Normal{Float64},
                                   Continuous}} # delta[z,l] ~ TN(m, s, 0, Inf)
  W_prior::Dirichlet # W_i ~ Dir_K(d)
  eta_prior::Dict{Int, Dirichlet{Float64}} # eta_zij ~ Dir_Lz(a)
  sig2_prior::InverseGamma # sig2_i ~ IG(shape, scale)
  sig2_range::Vector{Float64} # lower and upper bound for sig2
  beta::Matrix{Float64} # beta_dims x I, beta[:, i] refers to the beta's 
                        # for sample i
  eps_prior::Vector{Beta{Float64}} # I-dim
  K::Int
  L::Dict{Int, Int}

  # For repulsive Z
  probFlip_Z::Float64
  similarity_Z::Function
  noisyDist::ContinuousDistribution
  y_grid::Vector{Float64}
end


"""
yi: y[i] = N[i] x J matrix
pBounds = the bounds for probability of missing to compute the missing
          mechanism.
yQuantiles = the quantiles to compute the lower and upper bounds for y for the
             missing mechanism.
"""
function gen_beta_est(yi, yQuantiles, pBounds)
  yBounds = quantile(yi[yi .< 0], yQuantiles)
  return solveBeta(yBounds, pBounds)
end


"""
Genearte default values for constants
"""
function defaultConstants(data::Data, K::Int, L::Dict{Int, Int};
                          pBounds=[.01, .8, .05], yQuantiles=[0.01, .1, .25],
                          yBounds=missing,
                          sig2_prior=InverseGamma(3.0, 2 / 3),
                          sig2_range=[0.0, Inf],
                          alpha_prior = Gamma(3.0, 0.5),
                          tau0::Float64=0.0, tau1::Float64=0.0,
                          delta0_prior=TruncatedNormal(1.0, 1.0, 0.0, Inf),
                          delta1_prior=TruncatedNormal(1.0, 1.0, 0.0, Inf),
                          probFlip_Z::Float64=1.0 / (data.J * K),
                          noisyDist::ContinuousDistribution=Cauchy(),
                          y_grid::Vector{Float64}=collect(range(-10, stop=4,
                                                                length=100)),
                          similarity_Z::Function=sim_fn_abs(0))
  # Assert range of sig2 is positive
  @assert 0 <= sig2_range[1] < sig2_range[2]

  delta_prior = Dict{Int, Truncated{Normal{Float64}, Continuous}}()
  vec_y = vcat(vec.(data.y)...)
  y_neg = filter(y_inj -> !isnan(y_inj) && y_inj < 0, vec_y)
  y_pos = filter(y_inj -> !isnan(y_inj) && y_inj > 0, vec_y)
  if tau0 <= 0
    tau0 = std(y_neg)
  end
  if tau1 <= 0
    tau1 = std(y_pos)
  end
  delta_prior[0] = delta0_prior
  delta_prior[1] = delta1_prior

  W_prior = Dirichlet(K, 1 / K)
  eta_prior = Dict(z => Dirichlet(L[z], 1 / L[z]) for z in 0:1)
  eps_prior = [Beta(1.0, 99.0) for i in 1:data.I]

  # TODO: use empirical bayes to find these priors
  y_negs = [filter(y_i -> !isnan(y_i) && y_i < 0, vec(data.y[i]))
            for i in 1:data.I]
  if ismissing(yBounds)
    beta = hcat([gen_beta_est(y_negs[i], yQuantiles, pBounds)
                 for i in 1:data.I]...)
  else
    beta = hcat([solveBeta(yBounds, pBounds) for i in 1:data.I]...)
  end

  return Constants(alpha_prior=alpha_prior, delta_prior=delta_prior,
                   W_prior=W_prior, eta_prior=eta_prior,
                   sig2_prior=sig2_prior, sig2_range=sig2_range,
                   beta=beta, K=K, L=L,
                   probFlip_Z=probFlip_Z, similarity_Z=similarity_Z,
                   noisyDist=noisyDist, eps_prior=eps_prior, y_grid=y_grid)
end


function printConstants(c::Constants, preprintln::Bool=true)
  if preprintln
    println("Constants:")
  end

  for fname in fieldnames(typeof(c))
    x = getfield(c, fname)
    T = typeof(x)
    if T <: Number
      println("$fname: $x")
    elseif T <: Vector
      N = length(x)
      for i in 1:N
        println("$(fname)[$i]: $(x[i])")
      end
    elseif T <: Dict
      for (k, v) in x
        println("$(fname)[$k]: $v")
      end
    else
      println("$fname: $x")
    end
  end
end
