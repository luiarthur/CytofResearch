include("../PlotUtils/PlotUtils.jl")
include("../PlotUtils/imports.jl")
include("../util.jl")

using Distributed
rmprocs(filter(w -> w > 1, workers()))
addprocs(5)

@everywhere include("../PlotUtils/PlotUtils.jl")
@everywhere include("../PlotUtils/imports.jl")

cbdata, markernames = let
  Y_df = coalesce.(CSV.read("../data/cb_transformed_reduced_p0.9.csv", DataFrame), NaN)
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

  # Plot loglikelihood
  nburn = 10000
  loglike = output[:loglike]
  plt.plot(loglike[(nburn+1):end])
  plt.xlabel("sample number")
  plt.ylabel("log likelihood")
  plt.savefig(joinpath(imgdir, "loglike.pdf"), bbox_inches="tight")
  plt.close()

  # Return some summaries
  return (loglike=loglike, )
end

### MAIN ###

# Directory to CB runs results
results_dir = "results/revisions/cb-runs/mm_0/Kmcmc_21"

# Name of output file
OUTPUT_FILE = "output.bson"

# PATH TO ALL OUTPUT FILES
output_paths = [joinpath(root, OUTPUT_FILE)
                for (root, _, files) in walkdir(results_dir)
                if OUTPUT_FILE in files]

# Reproduce CB y, Z plots.
status = pmap(makeplots, output_paths, on_error=identity)
println.(typeof.(status));

# Print loglikelihoods to file
loglikes = getindex.(status, :loglike)
loglikes_df = DataFrame(loglikes, Symbol.("seed" .* string.(0:4)))
mkpath(joinpath(results_dir, "summary"))
CSV.write(joinpath(results_dir, "summary/loglikes.csv"), loglikes_df)

# Plot the loglikelihoods
for i in 3:4
  plt.plot(loglikes[i][10001:2:end], alpha=0.7)
end
plt.xlabel("Iteration (post-burn)")
plt.ylabel("log likelihood")
plt.savefig(joinpath(results_dir, "summary/loglikes.pdf"), bbox_inches="tight")
plt.close()

# TODO: beta for CB

println("DONE!")

# Push results to s3.
awsbucket ="s3://cytof-cb-results/cb-paper/revisions/"
s3sync(from="results/revisions", to=awsbucket, tags=`--exclude '*.nfs*'`)

# Get results from s3:
#=
s3sync(to="results/revisions", from=awsbucket, tags=`--exclude '*.nfs*'` --exclude '*.bson')
=#
