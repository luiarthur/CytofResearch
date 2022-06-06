# Minimal Example.

# Load the CytofResearch environment
import Pkg; Pkg.activate("..")


# Import libraries.
println("Loading libraries. Expect this to take a minute or two ...")
using CytofResearch
using Random
using BSON
using Distributions
println("Finished loading libraries ...")


# Helper function to randomly flip between zeros and ones.
flipbits(x; prob) = [prob > rand() ? 1 - xi : xi for xi in x]


# Helper method to simulate data for a simulation study.
function createSimData(; seed::Integer, N::Vector{<:Integer}, K=5, L=Dict(0=>3, 1=>3), J=20, eps=nothing)
	"""
  seed: A random number generator seed.
  N: The size of each dataset. i.e., the number of "cells" in each sample.
	"""
  # Number of samples.
  I = length(N)

	# Initialize eps with vector of zeros if eps is not provided.
	isnothing(eps) && (eps = zero.(N))

  # Set rng seed for reproducibility.
  Random.seed!(seed)

  # Initialize true Z matrix.
  Z = zeros(Int, J, K)
    
  # Regenerate Z unitl it is valid.
  while !CytofResearch.Model.isValidZ(Z)
    Z = CytofResearch.Model.genZ(J, K, .5)
    Z[:, 2] .= flipbits(Z[:, 1], prob=.1)
  end

  # Create true mu*
  mus = Dict(0 => -[1.0, 2.3, 3.5], 
             1 => +[1.0, 2.0, 3.0])

  # Create true a_W 
  a_W = rand(K) * 10

  # Create true a_eta
  a_eta = Dict(z => rand(L[z]) * 10 for z in 0:1)

  # Make simulated data
  simdat = CytofResearch.Model.genData(J=J, N=N, K=K, L=L, Z=Z,
                                beta=[-9.2, -2.3],
                                sig2=[0.2, 0.1, 0.3],
                                mus=mus,
                                a_W=a_W,
                                a_eta=a_eta,
                                sortLambda=false, propMissingScale=0.7,
                                eps=eps)
  return simdat
end

# Simulate data.
simdata = createSimData(seed=0, N=[800, 100, 200])

# Create model object for analysis.
dat = CytofResearch.Model.Data(simdata[:y])

# Make model constants
Kmcmc = 10
Lmcmc = Dict(0 => 5, 1 => 5)
@time c = CytofResearch.Model.defaultConstants(
	dat, Kmcmc, Lmcmc,
	tau0=10.0, tau1=10.0,
	sig2_prior=InverseGamma(3.0, 2.0),
	alpha_prior=Gamma(0.1, 10.0),
)

# Initialize MCMC cleverly..
println("Smart initializing ..."); flush(stdout)
@time init = CytofResearch.Model.smartInit(c, dat)

# Fit FAM.
results = CytofResearch.Model.cytof_fit(
	init,  # Initial value.
  c,  # model constants.
  dat;  # data for model.
	nmcmc=10,  # number of samples.
  nburn=10,  # number of iterations to discard.
)
