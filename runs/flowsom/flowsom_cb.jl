include("imports.jl")

# Path to scratch
RESULTS_DIR = "results"

# CB data path
CB_PATH = "../data/cb_transformed_reduced.csv"
SIM_SMALL_PATH = "../data/simdat-nfac500.bson"
SIM_LARGE_PATH = "../data/simdat-nfac5000.bson"

# Read CB data
function load_cb_data(path_to_data)
  function separatesamples(Y)
    sample_ids = sort(unique(Y.sample_id))
    return Matrix.(Y[Y.sample_id .== i, Not(:sample_id)]
                   for i in sample_ids)
  end

  Y = coalesce.(CSV.read(path_to_data), NaN)
  separatesamples(Y), names(Y)
end

load_simdata(path_to_data) = BSON.load(path_to_data)[:y]

function flowsanitize(Y)
  @rput Y
  return R"""
  colnames(Y) = 1:NCOL(Y)
  flowCore::flowFrame(Y)
  """
end

"""
replace missing values (NaN) in yi with x
"""
function replaceMissing(yi, x)
  out = deepcopy(yi)
  out[isnan.(out)] .= x
  return out
end


function main(y, markernames, outpath, K=30)
  I = length(y)
  N = [size(yi, 1) for yi in y]
  Y = replaceMissing(vcat(y...), -6)
  J = size(Y, 2)
  ff_Y = flowsanitize(Y)

  println("Running FlowSOM ...")
  @time fsom = FlowSOM.FlowSOM(ff_Y,
                               colsToUse=1:J,  # columns to use
                               maxMeta=K,  # Meta clustering option
                               seed=42)  # Seed for reproducible results:

  idx_upper = cumsum(N) 
  idx_lower = [1; idx_upper[1:end-1] .+ 1]
  idx = [idx_lower idx_upper]

  fsmeta = fsom[:metaclustering]
  fsclus = fsmeta[Int.(convert(Matrix, fsom[:FlowSOM][:map][:mapping])[:, 1])]

  mkpath(outpath)
  for i in 1:I
    # print output
    lami = fsclus[idx[i, 1]:idx[i, 2]]

    # Plot y
    Wi = zeros(K)
    Ni = length(lami)
    for lam_in in lami
      Wi[lam_in] += 1 / Ni
    end

    println("printing figure $i")
    plt.figure(figsize=(6, 6))
    PlotUtils.plot_yz.plot_y(y[i], Wi, lami, lw=3, vlim=(-4, 4),
                             cm=PlotUtils.blue2red.cm(9),
                             fs_xlab=PlotUtils.rcParams["font.size"],
                             fs_ylab=PlotUtils.rcParams["font.size"],
                             fs_lab=PlotUtils.rcParams["font.size"],
                             fs_cbar=PlotUtils.rcParams["font.size"],
                             markernames=markernames)
    plt.savefig("$(outpath)/y$(i).pdf", bbox_inches="tight")
    plt.close()

    # Write clusterings to disk
    writedlm("$(outpath)/lam$(i).txt", lami)

    # Write cluster sizes to disk
    writedlm("$(outpath)/W$(i).txt", Wi)
  end
end


### Main ###

# CB FlowSOM
println("Analyze CB ...")
y_cb, markernames_cb = load_cb_data(CB_PATH)
main(y_cb, markernames_cb, "results/cb")

# Sim Small FlowSOM
println("Analyze sim small ...")
main(load_simdata(SIM_SMALL_PATH), [], "results/sim-small")

# Sim Large FlowSOM
println("Analyze sim large ...")
main(load_simdata(SIM_LARGE_PATH), [], "results/sim-large")
