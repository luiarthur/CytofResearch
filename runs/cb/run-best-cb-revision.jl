println("Master node pid: $(getpid())")

include("../util.jl")
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

flush(stdout)
# TODO: Use the large numbers
NMCMC = 6  # 6000
NBURN = 10  # 10000
Kmcmcs = [21]  # best K
seeds = collect(0:4)
mm = 0

# Number of processors to use.
num_proc = length(seeds)

# Remove old workers
rmprocs(filter(w -> w > 1, workers()))

# Add processeors
println("Adding $(num_proc) workers ..."); flush(stdout)
addprocs(num_proc)

# Print worker process ids
worker_pids = pmap(id -> getpid(), workers())
println("Worker pids: $(join(worker_pids, " "))"); flush(stdout)

# Load the same libraries on worker nodes.
println("Loading libraries on worker nodes ..."); flush(stdout)
@everywhere include("imports.jl")
println("Finished loading libraries on workers node ..."); flush(stdout)


# Create model data object 
dat = let
  function separatesamples(Y)
    sample_ids = sort(unique(Y.sample_id))
    return Matrix.(DF.select(Y[Y.sample_id .== i, :], DF.Not(:sample_id))
                   for i in sample_ids)
  end

  path_to_data = "../data/cb_transformed_reduced_p0.9.csv"
  Y = coalesce.(CSV.read(path_to_data), NaN)
  y = separatesamples(Y)

  CytofResearch.Model.Data(y)
end

@everywhere function fit(Kmcmc::Int, nmcmc::Int, nburn::Int, dat, mm::Int, seed::Int)
  # Directory to store output.
  output_dir = "results/revisions/cb-runs/mm_$(mm)/Kmcmc_$(Kmcmc)/seed_$(seed)"

  # y quantiles for missing mechanism
  if mm == 0
    yQuantiles =  [0., 0.25, 0.5]
  elseif mm == 1
    yQuantiles =  [0., 0.2, 0.4]
  else
    yQuantiles =  [0., 0.15, 0.3]
  end

  # Create output directory if needed.
  mkpath(output_dir)

  # Redirect output to a file.
  CytofResearch.Model.redirect_stdout_to_file("$(output_dir)/log.txt") do
    println("Output directory: $(output_dir)"); flush(stdout)
    println("Worker node pid: $(getpid())"); flush(stdout)

    # Converts number of samples to thinning factor.
    nsamps_to_thin(nsamps::Int, nmcmc::Int) = max(1, div(nmcmc, nsamps))
    
    # Specification of L (as in model)
    Lmcmc = Dict(0 => 5, 1 => 3)

    # Set random seed for reproducibility.
    Random.seed!(seed)

    # Make model constants
    @time c = CytofResearch.Model.defaultConstants(
      dat, Kmcmc, Lmcmc,
      tau0=10.0, tau1=10.0,
      sig2_prior=InverseGamma(3.0, 2.0),
      alpha_prior=Gamma(0.1, 10.0),
      yQuantiles=yQuantiles,
      pBounds=[.05, .80, .05],
      similarity_Z=CytofResearch.Model.sim_fn_abs(10000),
      probFlip_Z=2.0 / (dat.J * Kmcmc),
      noisyDist=Normal(0.0, 10.0))

    # Print model constant for sanity.
    CytofResearch.Model.printConstants(c); flush(stdout)

    # Initialize MCMC smartly
    println("Smart initializing ..."); flush(stdout)
    @time init = CytofResearch.Model.smartInit(c, dat)

    # TODO: print probMissing curves

    # NOTE: This is the core of this script. It fits the FAM.
    # Everything else is setup / for parallelization.
    results = CytofResearch.Model.cytof_fit(
      init, c, dat;
      nmcmc=nmcmc, nburn=nburn, 
      monitors=[[:Z, :lam, :W, :sig2, :delta, :alpha, :v, :eta, :eps],
                [:y_imputed, :gam]],
      thins=[2, nsamps_to_thin(10, nmcmc)],
      printFreq=10,
      computeDIC=true, computeLPML=true,
      computedden=true,
      sb_ibp=false, use_repulsive=false,
      joint_update_Z=true)

    # Write to disk
    BSON.bson("$(output_dir)/output.bson", results)

    println("DONE!")
  end # end of redirect
end

# Run the thing in parallel
numjobs = length(Kmcmcs)
status = pmap(fit,
              Kmcmcs, fill(NMCMC, numjobs),
              fill(NBURN, numjobs), fill(dat, numjobs),
              fill(mm, numjobs), seeds,
              on_error=identity)
status_sanitized = map(s -> s == nothing ? "success" : s, status)

# Printing success / failure status of runs.
for (K, s) in zip(Kmcmcs, status_sanitized)
  println("Kmcmc: $(K) => status: $(s)")
end

println("ALL DONE!")

# Push results to s3.
awsbucket ="s3://cytof-cb-results/cb-paper/revisions/"
s3sync(from="results/revisions", to=awsbucket, tags=`--exclude '*.nfs'`)
