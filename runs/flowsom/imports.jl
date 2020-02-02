import Pkg
Pkg.activate(joinpath(@__DIR__, "../../"))

using BSON
using CSV
using Distributions
using DelimitedFiles
using DataFrames
using Random
using RCall

@rimport base
@rimport FlowSOM
@rimport flowCore

include(joinpath(@__DIR__, "../PlotUtils/PlotUtils.jl"))

import PyPlot
const plt = PyPlot.plt
PyPlot.matplotlib.use("Agg")
