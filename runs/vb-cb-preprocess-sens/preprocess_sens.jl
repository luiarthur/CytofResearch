import Pkg; 
Pkg.activate(joinpath(@__DIR__, "../../"))  # environment: CytofResearch

# Load libraries
println("Loading libraries ...")
import CSV
using DataFrames
include("../cb/PreProcess.jl")
println("Finished loading libraries.")

# Path to data.
data_dir = "../data"
path_to_data = "$(data_dir)/cb_transformed.csv"

function separatesamples(Y)
  sample_ids = sort(unique(Y.sample_id))
  return Matrix.(select(Y[Y.sample_id .== i, :], Not(:sample_id))
                 for i in sample_ids)
end

# Read transformed CB data into Y as a data frame.
# Replace `missing` with `NaN`.
function final_preprocess(Y; p=0.9, digits=3)
  markernames = filter(x -> x != :sample_id, names(Y))
  y = separatesamples(Y)
  isgoodmarker = PreProcess.preprocess!(y, maxNanOrNegProp=p,
                                        maxPosProp=p, rowThresh=-6.0)

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
  Y_reduced = DataFrame(vcat(y...), includedmarkers)

  # Convert NaN to missing
  Y_reduced = ifelse.(isnan.(Y_reduced), missing, Y_reduced)

  # Append a column for sample_id
  Y_reduced[!, :sample_id] = vcat([fill(i, size(y[i], 1))
                                   for i in 1:length(y)]...)

  return round.(Y_reduced, digits=digits), excludedmarkers
end

# Read data
Y = coalesce.(CSV.read(path_to_data), NaN)

# Excluded markers path.
path_to_excluded_markers = "excluded_markers.txt"
rm(path_to_excluded_markers, force=true)

for p in (0.85, 0.9, 0.95, 0.99)
  Y_reduced, excludedmarkers = final_preprocess(Y, p=p)

  open(path_to_excluded_markers, "a") do io
    println(io, "Excluded markers for p=$(p): $(String.(excludedmarkers))")
  end

  # Path to reduced data
  path_to_reduced_data = "$(data_dir)/cb_transformed_reduced_p$(p).csv"

  # Write reduced data to disk.
  println("Writing reduced-and-transformed CB data to: ")
  println(path_to_reduced_data)

  CSV.write(path_to_reduced_data, Y_reduced)
end
println("Done!")
