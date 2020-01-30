# TODO

include("../PlotUtils/PlotUtils.jl")
include("../PlotUtils/imports.jl")

using Distributed
# addprocs()  # TODO

@everywhere include("../PlotUtils/PlotUtils.jl")
@everywhere include("../PlotUtils/imports.jl")

@everywhere function makeplots(path_to_output)
  # TODO
end

### TEST ###
results_dir = "results/cb-runs"
include("../PlotUtils/PlotUtils.jl")
metrics = PlotUtils.make_metrics(results_dir, "output.bson", thresh=.01)
