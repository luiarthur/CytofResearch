include("../PlotUtils/PlotUtils.jl")
include("../PlotUtils/imports.jl")

# Name of output file
OUTPUT_FILE = "output.bson"

# Results directory for CB mm0
results_dir = "results/cb-runs/mm_0"

# Reproduce CB metrics
println("Producing metrics ...")
metrics = PlotUtils.make_metrics(results_dir, OUTPUT_FILE, thresh=.01)

# Missmech vs LPML, DIC
LPML = Float64[]
DIC = Float64[]
q = [(0., 0.25, 0.5),  # mm0
     (0, 0.2, 0.4),  # mm1
     (0, 0.15, 0.3)]  # mm2
rho = (.05, .8, .05)
betas = Dict{Int, Any}()  # betas in missing mechanism

for mm in 0:2
  output_path = "results/cb-runs/mm_$(mm)/Kmcmc_21/output.bson"
  out = BSON.load(output_path)
  metrics = out[:metrics]
  append!(LPML, metrics[:LPML])
  append!(DIC, metrics[:DIC])
  betas[mm] = out[:c].beta
end

# Number of CB samples
num_samples = size(betas[0], 2)

# Data frame comparing missing mechanisms and LPML / DIC
mm_compare_df = DataFrames.DataFrame(missing_mech=0:2, q=q,
                                     rho=rho, LPML=LPML, DIC=DIC)

# Write data frame. (separated by semi-colon)
CSV.write("results/mm_compare.csv", mm_compare_df, delim=';')

# Data frame for betas in each missing mechanism
mm_betas_df = vcat([DataFrames.DataFrame(
  let
    d = Dict(:missmech => mm,
             :beta => ["beta_$(k)" for k in 0:2])
    for i in 1:size(betas[mm], 2)
      d[Symbol("sample_$(i)")] = betas[mm][:, i]
    end
    d
  end) for mm in 0:2]...)

# Reorder columns for aesthetics
mm_betas_df = mm_betas_df[vcat([:missmech, :beta],
                               [Symbol("sample_$(i)") for i in 1:num_samples])]

# Write data frame.
CSV.write("results/mm_betas.csv", mm_betas_df)

