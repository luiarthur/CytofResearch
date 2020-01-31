println("Master node pid: $(getpid())")

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


# Number of processors to use.
if length(ARGS) == 0
  # NOTE: This is for testing.
  println("Running in debug mode! This does not reproduce results in paper!")
  flush(stdout)

  num_proc = 20
  NMCMC = 20
  NBURN = 10
  MONITORS=[[:Z, :lam, :W, :sig2, :delta, :alpha, :v, :eta, :eps]]
  THINS=[2]
  YQUANTILES = [0.0, 0.25, 0.50]
  Kmcmcs_small = [3, 5, 7]
  Kmcmcs_large = [5, 10, 15]
  EXP_NAME_SUFFIX = "mm0"
else
  # Converts number of samples to thinning factor.
  nsamps_to_thin(nsamps::Int, nmcmc::Int) = max(1, div(nmcmc, nsamps))

  num_proc = parse(Int, ARGS[1])
  Kmcmcs_small = parse.(Int, split(ARGS[2], ","))
  Kmcmcs_large = parse.(Int, split(ARGS[3], ","))
  YQUANTILES = parse.(Float64, split(ARGS[4], ","))
  EXP_NAME_SUFFIX = ARGS[5]

  NMCMC = 6000
  NBURN = 10000
  MONITORS=[[:Z, :lam, :W, :sig2, :delta, :alpha, :v, :eta, :eps],
            [:y_imputed, :gam]]
  THINS=[2, nsamps_to_thin(10, NMCMC)]
end

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
small_simdat = let
  y = Matrix.(BSON.load("../data/simdat-nfac500.bson")[:y])
  CytofResearch.Model.Data(y)
end

large_simdat = let
  y = Matrix.(BSON.load("../data/simdat-nfac5000.bson")[:y])
  CytofResearch.Model.Data(y)
end

@everywhere small_simdat = $(small_simdat)
@everywhere large_simdat = $(large_simdat)

# Kmcmc, nmcmc, nburn, simdatsize, dat, monitors, thins
@everywhere function fit(setting)
  for (key, val) in setting
    println("$(key) => $(val)"); flush(stdout)
  end

  Kmcmc = setting[:Kmcmc]
  nmcmc = setting[:nmcmc]
  nburn = setting[:nburn]
  simdatsize = setting[:simdatsize]
  dat = (simdatsize == "small") ? small_simdat : large_simdat
  monitors = setting[:monitors]
  thins = setting[:thins]
  yQuantiles = setting[:yQuantiles]
  suffix = setting[:suffix]

  # Directory to store output.
  output_dir = "results/sim-runs-$(simdatsize)/$(suffix)/Kmcmc_$(Kmcmc)"

  # Create output directory if needed.
  mkpath(output_dir)

  # Redirect output to a file.
  CytofResearch.Model.redirect_stdout_to_file("$(output_dir)/log.txt") do
    println("Output directory: $(output_dir)"); flush(stdout)
    println("Worker node pid: $(getpid())"); flush(stdout)
    
    # Specification of L (as in model)
    Lmcmc = Dict(0 => 5, 1 => 5)

    # Set random seed for reproducibility.
    if simdatsize == "small"
      Random.seed!(90)
    else
      Random.seed!(1)
    end

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

    # TODO: print initial Z

    # NOTE: This is the core of this script. It fits the FAM.
    # Everything else is setup / for parallelization.
    results = CytofResearch.Model.cytof_fit(
      init, c, dat;
      nmcmc=nmcmc, nburn=nburn, 
      monitors=monitors,
      thins=thins,
      printFreq=10,
      computeDIC=true, computeLPML=true,
      computedden=true,
      sb_ibp=false, use_repulsive=false,
      joint_update_Z=true)

    # Write to disk
    BSON.bson("$(output_dir)/output.bson", results)
  end # end of redirect

  return
end

# Run the thing in parallel

# Kmcmc, nmcmc, nburn, simdatsize, dat, monitors, thins
settings = vcat(
  [Dict(:Kmcmc => K, :nmcmc => NMCMC, :nburn => NBURN, :simdatsize => "small",
        :monitors => MONITORS, :thins => THINS, :yQuantiles => YQUANTILES,
        :suffix => EXP_NAME_SUFFIX)
   for K in Kmcmcs_small],
  [Dict(:Kmcmc => K, :nmcmc => NMCMC, :nburn => NBURN, :simdatsize => "large",
        :monitors => MONITORS, :thins => THINS, :yQuantiles => YQUANTILES,
        :suffix => EXP_NAME_SUFFIX)
   for K in Kmcmcs_large])

# status = pmap(fit, settings, on_error=identity)
status = pmap(fit, settings)
status_sanitized = map(s -> s == nothing ? "success" : s, status)

# Printing success / failure status of runs.
for (se, st) in zip(settings, status_sanitized)
  println("setting: $(se) => status: $(st)")
end
