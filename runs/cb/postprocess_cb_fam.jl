# TODO

include("../PlotUtils/PlotUtils.jl")

using Distributed
# addprocs()  # TODO

@everywhere function makeplots(path_to_output)
  # TODO
end

function plotmetrics(results_dir)
  # TODO
  # - LPML
  # - DIC
  # - number of W < 1%
end
