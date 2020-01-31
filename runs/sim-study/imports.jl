import Pkg
Pkg.activate(joinpath(@__DIR__, "../../"))  # environment: CytofResearch

using BSON
using CSV
using CytofResearch
import DataFrames; const DF = DataFrames
using Distributions
import Random
