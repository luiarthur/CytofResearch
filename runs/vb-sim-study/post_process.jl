include("../vb-cb/plot_vb_results.jl")

using Distributed
addprocs(10)

@everywhere include("../vb-cb/plot_vb_results.jl")

# Path to simulation data
path_to_data = ARGS[1]
results_dir = ARGS[2]

@everywhere path_to_data = $(path_to_data)

# Read CB data
@everywhere y = Matrix.(BSON.load(path_to_data)[:y])

paths = [joinpath(root, file)
         for (root, dirs, files) in walkdir(results_dir)
         for file in files
         if file == "output.bson"]

@everywhere function makegraph(path)
  println("Processing: $(path)"); flush(stdout)
  makeplots(y=y, path_to_output=path, markernames=[], nlam=30)
  return
end

# Make graphs in parallel
status = pmap(makegraph, paths, on_error=identity)
println(status)
