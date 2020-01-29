module Model

using Distributions

using RCall  # Mclust

import LinearAlgebra  # Identity matrix
import Random  # shuffle, seed!
import StatsBase  # wsample, counts

include("../MCMC/MCMC.jl")
import .MCMC.Util.@namedargs

include("util.jl")
include("DICparam.jl")
include("State.jl")
include("Data.jl")
include("Constants.jl")
include("Tuners.jl")
include("repFAM/repFAM.jl")
include("update.jl")
include("FeatureSelect/FeatureSelect.jl")
include("genInitialState.jl")
include("fit.jl")

#=
precompile(cytof_fit, (State, Constants, Data, Int, Int,
                       Vector{Vector{Symbol}}, Vector{Int}, Bool, Int, Bool,
                       Bool, Bool))
=#

end # Model
