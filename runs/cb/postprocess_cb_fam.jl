include("../PlotUtils/PlotUtils.jl")
include("../PlotUtils/imports.jl")

using Distributed
rmprocs(filter(w -> w > 1, workers()))
addprocs(13)

@everywhere include("../PlotUtils/PlotUtils.jl")
@everywhere include("../PlotUtils/imports.jl")

cbdata, markernames = let
  Y_df = coalesce.(CSV.read("../data/cb_transformed_reduced.csv"), NaN)
  _markernames = filter(n -> n != :sample_id, names(Y_df))
  _cbdata = Matrix.(select(Y_df[Y_df.sample_id .== i, :], Not(:sample_id))
                    for i in unique(Y_df.sample_id))
  _cbdata, _markernames
end

@everywhere cbdata = $(cbdata)
@everywhere markernames = $(markernames)
@everywhere m = [isnan.(yi) for yi in cbdata]

@everywhere function makeplots(path_to_output)
  println(path_to_output)
  output = BSON.load(path_to_output)
  extract(s) = map(o -> o[s], output[:out][1])
  Zs = extract(:Z)
  Ws = extract(:W)
  lams = extract(:lam)

  # Create a directory for images if needed.
  dir_to_output, _ = splitdir(path_to_output)
  imgdir = joinpath(dir_to_output, "img", )
  mkpath(imgdir)

  PlotUtils.make_yz(cbdata, Zs, Ws, lams, imgdir, vlim=(-4,4),
                    markernames=markernames)
end

### MAIN ###

# Directory to CB runs results
results_dir = "results/cb-runs"

# Name of output file
OUTPUT_FILE = "output.bson"

# PATH TO ALL OUTPUT FILES
output_paths = [joinpath(root, OUTPUT_FILE)
                for (root, _, files) in walkdir(results_dir)
                if OUTPUT_FILE in files]

# Reproduce CB y, Z plots.
status = pmap(makeplots, output_paths)
println(status)

# TODO: beta for CB



println("DONE!")
