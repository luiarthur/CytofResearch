import Pkg

path_to_env = joinpath(@__DIR__, "../../")
Pkg.activate(path_to_env)

using CytofResearch
using BSON
using Distributions
using LaTeXStrings
using DataFrames
using CSV
using DelimitedFiles
include(joinpath(@__DIR__, "salso.jl"))

import PyCall, PyPlot
const plt = PyPlot.plt
PyPlot.matplotlib.use("Agg")

#= Interactive plot
PyPlot.matplotlib.use("TkAgg")
=#
#= Non-interactive plot 
PyPlot.matplotlib.use("Agg")
=#


# TODO
# Steal things from: Cytof5/sims/repfam_fs/test
