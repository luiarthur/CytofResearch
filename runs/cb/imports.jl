import Pkg
Pkg.activate("../../")  # environment: CytofResearch

using BSON
using CSV
using CytofResearch
import DataFrames; const DF = DataFrames
using Distributions
import Random
