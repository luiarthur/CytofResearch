include("plot_vb_results.jl")

# Read CB data
y, markernames = let
  function separatesamples(Y)
    sample_ids = sort(unique(Y.sample_id))
    return Matrix.(Y[Y.sample_id .== i, Not(:sample_id)]
                   for i in sample_ids)
  end

  path_to_data = "../data/cb_transformed_reduced.csv"
  Y = coalesce.(CSV.read(path_to_data), NaN)
  (separatesamples(Y), names(Y))
end

paths = [joinpath(root, file)
         for (root, dirs, files) in walkdir("results")
         for file in files
         if file == "output.bson"]

for path in paths
  println("Processing: $(path)")
  makeplots(y=y, path_to_output=path,
            markernames=markernames, nlam=30)
end
