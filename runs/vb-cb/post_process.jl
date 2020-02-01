# TODO: MAke this a module, and test this.
# THIS IS NEXT!
include("../PlotUtils/PlotUtils.jl")
include("../PlotUtils/imports.jl")
include("sample/sample_lam.jl")

# Function arguments
nsamps = 100
output = BSON.load("results/seed_2/output.bson")
imgdir = "results/seed_2/img"
mkpath(imgdir)
w_thresh = .01
# y
# markernames = 

state = output[:state]
c = output[:c]
samples = [CytofResearch.VB.rsample(state)[2] for _ in 1:nsamps]

# Compute Z and E[Z]
compute_Z(s) = Int.(reshape(s.v, 1, c.K) .> s.H).data
Zs = compute_Z.(samples)
Zmean = mean(Zs)

# Compute W
Ws = [s.W for s in samples]
Wmean = mean(Ws).data

# Compute lam
nlam = 30
lams = [begin
          print("\rsampling lambda: $(b)/$(nlam)")
          sample_lam(state, y, c)
        end for b in 1:nlam]
println()
lam_est = [mode(lam[i] for lam in lams) for i in 1:length(lams[1])]

i = 1
# TODO: markernames=???
PlotUtils.plot_yz.plot_Z(Zmean, Wmean[i, :], lam_est[i], w_thresh=w_thresh)
plt.savefig("$(imgdir)/Z$(i).pdf", bbox_inches="tight")
plt.close()
