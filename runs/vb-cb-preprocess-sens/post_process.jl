include(joinpath(@__DIR__, "../vb-cb/plot_vb_results.jl"))  # To precompile 

using Distributed
addprocs(10)

@everywhere include(joinpath(@__DIR__, "../vb-cb/plot_vb_results.jl"))

@everywhere function separatesamples(Y)
  sample_ids = sort(unique(Y.sample_id))
  return Matrix.(Y[Y.sample_id .== i, Not(:sample_id)]
                 for i in sample_ids)
end

@everywhere function get_attr(path)
  p = match(r"(?<=p)\d+\.\d+", path).match
  seed = match(r"(?<=seed)\d+", path).match
  return (p=parse(Float64, p),
          seed=parse(Int, seed))
end

@everywhere function postprocess(path)
  # Read CB data
  y, markernames = let
    p, seed = get_attr(path)
    data_path = "../data/cb_transformed_reduced_p$(p).csv"
    Y = coalesce.(CSV.read(data_path), NaN)
    (separatesamples(Y), names(Y))
  end

  println("Processing: $(path)")
  makeplots(y=y, path_to_output=path,
            markernames=markernames, nlam=30)
end

# List of paths to results.
paths = [joinpath(root, file)
         for (root, dirs, files) in walkdir("results")
         for file in files
         if file == "output.bson"]

# Post process in parallel
status = pmap(postprocess, paths, on_error=identity)
status_sanitized = map(s -> s == nothing ? "success" : s, status)

# Printing success / failure status of runs.
for (path, s) in zip(paths, status_sanitized)
  println("$(path) => status: $(s)")
end

println("ALL DONE!")
