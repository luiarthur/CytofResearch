import Pkg; Pkg.activate("../../")

println("Loading libraries ...")
include("PreProcess.jl")
import CSV
import DataFrames; const DF = DataFrames
println("Finished loading libraries.")

data_dir = "../data"
path_to_data = "$(data_dir)/cb_transformed.csv"

function separatesamples(Y)
  sample_ids = sort(unique(Y.sample_id))
  return Matrix.(DF.select(Y[Y.sample_id .== i, :], DF.Not(:sample_id))
                 for i in sample_ids)
end

# Read transformed CB data into Y as a data frame.
# Replace `missing` with `NaN`.
Y = coalesce.(CSV.read(path_to_data), NaN)
markernames = filter(x -> x != :sample_id, names(Y))
y = separatesamples(Y)
isgoodmarker = PreProcess.preprocess!(y, maxNanOrNegProp=.9,
                                      maxPosProp=.9, rowThresh=-6.0)

includedmarkers = Symbol[]
excludedmarkers = Symbol[]

for j in 1:length(isgoodmarker)
  marker = markernames[j]
  if isgoodmarker[j]
    append!(includedmarkers, [marker])
  else
    append!(excludedmarkers, [marker])
  end
end

# Concatenate y and convert to data frame
Y_reduced = DF.DataFrame(vcat(y...), includedmarkers)


# Convert NaN to missing
Y_reduced = ifelse.(isnan.(Y_reduced), missing, Y_reduced)

# Append a column for sample_id
Y_reduced[!, :sample_id] = vcat([fill(i, size(y[i], 1))
                                 for i in 1:length(y)]...)

# Path to reduced data
path_to_reduced_data = "$(data_dir)/cb_transformed_reduced.csv"

# Write reduced data to disk.
println("Writing reduced-and-transformed CB data to: ")
println(path_to_reduced_data)

CSV.write(path_to_reduced_data, Y_reduced)

println("Done!")
