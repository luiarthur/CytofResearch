include(joinpath(@__DIR__, "../vb-cb/plot_vb_results.jl"))  # To precompile 

using Distributed
addprocs(4)

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

function get_best_seed_for_p(paths, p)
  p_paths = filter(path -> match(Regex(string(p)), path) != nothing, paths)
  elbos = [let
             f = open(readlines, joinpath(dirname(path), "log.txt"))
             seed = parse(Int, match(r"(?<=seed)\d+", path).match)
             elbo = parse(Float64, match(r"(?<=elbo: )-\d+\.\d+", f[end - 1]).match)
             (elbo, seed)
           end for path in p_paths]
  best_idx = argmax([elbo[1] for elbo in elbos])
  best_seed = elbos[best_idx][2]
  return best_seed
end

# List of paths to results.
paths = [joinpath(root, file)
         for (root, dirs, files) in walkdir("results")
         for file in files
         if file == "output.bson"]

# ps used.
ps = unique([parse(Float64, m.match) for m in match.(r"(?<=p)\d+\.\d+", paths)])
best_seeds = Dict(p => get_best_seed_for_p(paths, p) for p in ps)
best_paths = ["results/p$(p)_seed$(s)/output.bson" for (p, s) in best_seeds]

# Post process in parallel
@time status = pmap(postprocess, best_paths, on_error=identity)
status_sanitized = map(s -> s == nothing ? "success" : s, status)

# Printing success / failure status of runs.
for (path, s) in zip(best_paths, status_sanitized)
  println("$(path) => status: $(s)")
end

println("ALL DONE!")
