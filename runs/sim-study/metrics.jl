include("../PlotUtils/PlotUtils.jl")
include("../PlotUtils/imports.jl")

# Reproduce sims metrics

# Name of output file
OUTPUT_FILE = "output.bson"

println("Producing metrics ...")

results_dirs = ["results/sim-runs-$(dsize)/mm0/"
                for dsize in ("small", "large")]

for d in results_dirs
  println(d)
  metrics = PlotUtils.make_metrics(d, OUTPUT_FILE, thresh=.01)
end


# Missmech vs LPML, DIC
function mm_compare(datsize)
  if datsize == "small"
    results_dir = "results/sim-runs-small"
    output_paths = ["$(results_dir)/mm$(mm)/Kmcmc_5/output.bson" for mm in 0:2]
  else
    results_dir = "results/sim-runs-large"
    output_paths = ["$(results_dir)/mm$(mm)/Kmcmc_10/output.bson" for mm in 0:2]
  end

  LPML = Float64[]
  DIC = Float64[]
  q = [(0., 0.25, 0.5),  # mm0
       (0, 0.2, 0.4),  # mm1
       (0, 0.15, 0.3)]  # mm2
  rho = (.05, .8, .05)

  for p in output_paths
    metrics = BSON.load(p)[:metrics]
    append!(LPML, metrics[:LPML])
    append!(DIC, metrics[:DIC])
  end

  # Data frame comparing missing mechanisms and LPML / DIC
  mm_compare_df = DataFrames.DataFrame(missing_mech=0:2, q=q,
                                       rho=rho, LPML=LPML, DIC=DIC)

  # Write data frame. (separated by semi-colon)
  CSV.write("$(results_dir)/mm_compare.csv", mm_compare_df, delim=';')
end

foreach(mm_compare, ["small", "large"])

println("DONE!")

