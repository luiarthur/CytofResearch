# Minimal Example

`scripts/example.jl` contains a minimal example for running the feature
allocation model (FAM) in "A Bayesian Feature Allocation Model for
Identification of Cell Subpopulations Using CyTOF Data".

## System Requirements

The only system requirements are Julia v1.3 and a Fortran compiler. Other Julia versions
may not be compatible with the software dependencies in the `CytofResearch` library.

You can download and install Julia v1.3 from: https://julialang.org/downloads/oldreleases/


## Reproducing the project environment

To replicate the project environment for `CytofResearch`, simply execute in a UNIX terminal
```
make init
```
from the current directory. This will install required libraries, including a
clean installation of the R programming language, to be used within Julia. The
`mclust` R package will be installed if needed. A current Fortran compiler is
needed to compile `mclust`.


## Walking through the example

For this demo, first go to `scripts` directory from the terminal. Then, launch
a Julia (v1.3) REPL. In the REPL, you can activate the virtual environment for
this demo by 
```julia
# Load the CytofResearch environment
import Pkg; Pkg.activate("..")
```

The libraries required for this demo can be loaded via:
```julia
# Import libraries.
println("Loading libraries. Expect this to take a minute or two ...")
using CytofResearch
using Random
using BSON
using Distributions
println("Finished loading libraries ...")
```

The following methods are used to generate synthetic CyTOF data. The data will
be stored in a dictionary, with the most important entry being `:y`, which
is an array of matrices, each row representing marker expression levels for
each cell.
```julia
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
```

Here, we actually generate synthetic data. Note that `seed` is a random number
generator seed; and `N` is a vector containing the number of "cells" for each
sample. `simdata` is a dicionary, with the most important entry being `:y`,
which contains an array of matrices, with each row in each matrix containing
marker expression levels for a "cell".
```julia
# Simulate data.
simdata = createSimData(seed=0, N=[800, 100, 200])

# Dict{Symbol,Any} with 11 entries:
#   :eps        => [0, 0, 0]
#   :y_complete => Array{Float64,2}[[2.79179 1.61442 … 1.2592 -1.30717; 2.91528 1.66226 … -2.08797 ; … ; -1.03721 … 1.44618 -3.69683; 1.84077 …
#   :eta        => Dict(0=>[0.193974 0.379377 … 0.285754 0.505211; 0.311776 0.339833 … 0.221715 0.349306; 0.340217 0.318064 … 0.219527 0.331437]…
#   :gam        => Array{Int64,2}[[2 2 … 1 1; 3 2 … 1 2; … ; 2 1 … 1 3; 2 2 … 1 1], [1 3 … 3 1;  … ; 1 3 … 3 3; 1 3 … 3 3], [3 2 … 3 1; 3 1 … 3 3; ……
#   :Z          => [1 1 … 1 1; 1 1 … 1 0; … ; 0 0 … 1 1; 0 0 … 0 0]
#   :sig2       => [0.2, 0.1, 0.3]
#   :mus        => Dict(0=>[-1.0, -2.3, -3.5],1=>[1.0, 2.0, 3.0])
#   :lam        => Array{Int64,1}[[4, 2, 1, 2, 5, 1, 5, 1, 5, 5  …  1, 5, 2, 3, 1, 5, 5, 4, 5, 5], [4, 3, 4, 3, 5, 2,   …  2, 5, 5, 3, 2, 4, 4…
#   :beta       => [-9.2, -2.3]
#   :y          => Array{Float64,2}[[2.79179 1.61442 … 1.2592 -1.30717; 2.91528 1.66226 … -2.08797 -1.98176; … ; 1.63542 -1.03721 … 1.44618 -3.69683; …
#   :W          => [0.28041 0.0664152 … 0.0601489 0.466229; 0.0511902 0.279615 … 0.299759 0.072132; 0.23731 0.0444619 … 0.152463 0.31256]
```

Here we have some boilerplate to generate information for the model. `dat`
contains information about the sizes of the matrices in `simdat[:y]`.
`constants` contains information such as the number of latent features (`K`)
and the number of mixture model components (`L`) for estimating the density of
the marker expression patterns. Other information in `constants` are related
to priors and the missing mechanism.

```julia
# Create model object for analysis.
dat = CytofResearch.Model.Data(simdata[:y])


# Make model constants
K = 10  # number of latent features.
L = Dict(0 => 5, 1 => 5)  # number of mixture model components for density estimation.
@time constants = CytofResearch.Model.defaultConstants(
	dat, K, L,
	tau0=10.0, tau1=10.0,  # prior hyperparameters.
	sig2_prior=InverseGamma(3.0, 2.0),  # prior distribution for sigma squared.
	alpha_prior=Gamma(0.1, 10.0),  # prior distribution for alpha.
	yQuantiles=[0.0, 0.25, 0.50],  # for setting the missing data mechanism
	pBounds=[.05, .80, .05],  # for setting the missing data mechanism
)
```

Initialization of the `mu` stars is done via the mclust package, as indicated in the paper.
The following method does the initialization.
```julia
# Initialize MCMC cleverly..
println("Smart initializing ..."); flush(stdout)
@time init = CytofResearch.Model.smartInit(constants, dat)
```

The `cytof_fit` method takes an initial value, model constants, and data, along
with specifications for the MCMC (number of samples, burn-in period), and runs
MCMC. The result is a dicionary containing 
- `:lastState`: the last state of the MCMC
- `:out`: the posterior samples in the form of an array of objects
- `:c`: the model constants 
- `:init`: the initial value
- `:loglike`: a trace of the loglikelihood

```julia
# Fit FAM.
results = CytofResearch.Model.cytof_fit(
	init,  # Initial value.
  c,  # model constants.
  dat;  # data for model.
	nmcmc=1000,  # number of samples.
  nburn=10000,  # number of iterations to discard.
)
```
