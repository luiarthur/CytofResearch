# Load the CytofResearch environment
import Pkg; Pkg.activate("../../")

println("Loading libraries. Expect this to take a minute or two ...")
using CytofResearch
using Random
using BSON
println("Finished loading libraries ...")

flipbits(x; prob) = [prob > rand() ? 1 - xi : xi for xi in x]

function createSimData(;seed::Int, nfac::Int, 
                       K=5, L=Dict(0=>3, 1=>3), J=20, eps=zeros(3))

  N = [8, 1, 2] * nfac
  I = length(N)

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

### Main ###
settings = [Dict(:nfac => 500, :K => 5, :seed => 90),
            Dict(:nfac => 5000, :K => 10, :seed => 1)]

for setting in settings
  nfac = setting[:nfac]
  seed = setting[:seed]
  K = setting[:K]

  println("Creating simulated data with: $(setting)")
  simdat = createSimData(seed=seed, nfac=nfac,
                         K=K, L=Dict(0=>3, 1=>3), J=20, eps=fill(.005, 3))

  # Save simulated data
  path_to_simdat = "../data/simdat-nfac$(nfac).bson"
  BSON.bson(path_to_simdat, simdat)
end

# NOTE: The ".bson" file is cross-platform, but requires the same BSON version.
#       To load the simulated data:
# simdat_small = BSON.load("../data/simdat-nfac500.bson")
# simdat_large = BSON.load("../data/simdat-nfac5000.bson")
