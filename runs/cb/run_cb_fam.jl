println("pid: $(getpid())")

# Load libraries on master node.
# NOTE: In theory, this step is not needed. In practice, this step
# guarantees that libraries are compiled and cached before they
# are used by the workers. If this is not done, workers may
# try to compile the same library simultaneously and write the compiled cache
# to the same locatoin.
println("Loading libraries on master node ...")
include("imports.jl")
println("Finished loading libraries on master node ...")

using Distributed

# Number of processors to use.
num_proc = (length(ARGS) == 0) ? nprocs() / 2 : parse(Int, ARGS[1])
println("Adding $(num_proc) workers ...")
addprocs(num_proc)

# Load the same libraries on worker nodes.
println("Loading libraries on worker nodes ...")
@everywhere include("imports.jl")
println("Finished loading libraries on workers node ...")

@everywhere function fit(K::Int)
  nsamps_to_thin(nsamps::Int, nmcmc::Int) = max(1, div(nmcmc, nsamps))

  # TODO. See Cytof5/sims/cb/cb.jl

  init = #TODO
  c = #TODO
  d = #TODO
  cytof_fit(init, c, d;
            nmcmc::Int=6000, nburn::Int=10000, 
            monitors=[[:Z, :lam, :W,
                       :sig2, :delta,
                       :alpha, :v,
                       :eta, :eps]],
            fix::Vector{Symbol}=Symbol[],

            thins::Vector{Int}=[1],
            thin_dden::Int=1,
            printFreq::Int=0, flushOutput::Bool=false,
            computeDIC::Bool=false, computeLPML::Bool=false,
            computedden::Bool=false,
            sb_ibp::Bool=false,
            use_repulsive::Bool=false, joint_update_Z::Bool=false,
            verbose::Int=1)
end

# Run the thing in parallel
Kmcmcs = collect(3:3:33)
status = pmap(fit, Kmcmcs, on_error=identity)

# Printing success / failure status of runs.
for (K, s) in zip(Kmcmcs, 1:length(status))
  println("K: $(K) => status: $(s)")
end
