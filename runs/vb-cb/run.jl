println("Master node pid: $(getpid())"); flush(stdout)

# Load libraries on master node.
# NOTE: In theory, this step is not needed. In practice, this step
# guarantees that libraries are compiled and cached before they
# are used by the workers. If this is not done, workers may
# try to compile the same library simultaneously and write the compiled cache
# to the same locatoin.
println("Compile libraries on master node ..."); flush(stdout)
include("imports.jl")
println("Finished compiling libraries on master node ..."); flush(stdout)

using Distributed

# Parse command line args
if length(ARGS) == 0
  println("Running in debug mode! This does not reproduce results in paper!")
  flush(stdout)

  num_proc = 2
  SEEDS = [2, 4]
  NITERS = 20000
  BATCHSIZE = 200
else
  num_proc = parse(Int, ARGS[1])  # 20
  SEEDS = collect(1:10)
  NITERS = 20000
  BATCHSIZE = 2000
end

# Remove old workers
rmprocs(filter(w -> w > 1, workers()))

# Add processeors
println("Adding $(num_proc) workers ..."); flush(stdout)
addprocs(num_proc)

@everywhere NITERS = $(NITERS)
@everywhere BATCHSIZE = $(BATCHSIZE)

# Print worker process ids
worker_pids = pmap(id -> getpid(), workers())
println("Worker pids: $(join(worker_pids, " "))"); flush(stdout)

# Load the same libraries on worker nodes.
println("Loading libraries on worker nodes ..."); flush(stdout)
@everywhere include("imports.jl")
println("Finished loading libraries on workers node ..."); flush(stdout)


# Read data and make available on on processors
@everywhere y = let
  function separatesamples(Y)
    sample_ids = sort(unique(Y.sample_id))
    return Matrix.(Y[Y.sample_id .== i, DF.Not(:sample_id)]
                   for i in sample_ids)
  end

  path_to_data = "../data/cb_transformed_reduced.csv"
  Y = coalesce.(CSV.read(path_to_data), NaN)
  separatesamples(Y)
end

@everywhere function fit(seed)
  # Results directory
  results_dir = "results/seed_$(seed)"
  mkpath(results_dir)

  # Redirect output
  CytofResearch.Model.redirect_stdout_to_file("$(results_dir)/log.txt") do
    # Set random seed for reproducibiliyu
    Random.seed!(seed)
    println("seed: $(seed)")

    # Generate model constants
    c = CytofResearch.VB.Constants(y=y, K=30, L=Dict(false => 5, true => 3),
                                   yQuantiles=[.0, .25, .5], pBounds=[.05, .8, .05],
                                   use_stickbreak=false, tau=.001)
    c.priors.eps = Beta(1, 99)
    c.priors.sig2 = Gamma(.1, 1)

    # Fit model
    out = CytofResearch.VB.fit(y=y, niters=NITERS, batchsize=BATCHSIZE, c=c,
                               nsave=30, seed=seed)

    # Save results
    BSON.bson("$(results_dir)/output.bson", out)
  end  # of redirect

  return
end

# Run the thing in parallel
status = pmap(fit, SEEDS, on_error=identity)
status_sanitized = map(s -> s == nothing ? "success" : s, status)

# Printing success / failure status of runs.
for (seed, s) in zip(SEEDS, status_sanitized)
  println("seed: $(seed) => status: $(s)")
end

println("ALL DONE!")
