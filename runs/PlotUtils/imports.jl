import Pkg

path_to_env = joinpath(@__DIR__, "../../")
Pkg.activate(path_to_env)

using CytofResearch
using BSON

import PyCall, PyPlot, Seaborn
const plt = PyPlot.plt
const sns = Seaborn
