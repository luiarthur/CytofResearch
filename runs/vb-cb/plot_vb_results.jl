include(joinpath(@__DIR__, "../PlotUtils/PlotUtils.jl"))
include(joinpath(@__DIR__, "../PlotUtils/imports.jl"))
include(joinpath(@__DIR__, "sample/sample_lam.jl"))

using CytofResearch, Flux.Tracker

function makeplots(; y, path_to_output, nsamps=100, w_thresh=.01, lw=3,
                   vlim=(-4, 4), markernames=[], nlam=30,
                   fs_y=PlotUtils.rcParams["font.size"],
                   fs_z=PlotUtils.rcParams["font.size"],
                   fs_ycbar=PlotUtils.rcParams["font.size"],
                   fs_zcbar=PlotUtils.rcParams["font.size"])

  output = BSON.load(path_to_output)
  imgdir = joinpath(splitdir(path_to_output)[1], "img")
  mkpath(imgdir)

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

  # Number of CB samples
  num_cb_samples = size(Wmean, 1)

  # Compute lam
  lams = [begin
            print("\rsampling lambda: $(b)/$(nlam)")
            sample_lam(state, y, c)
          end for b in 1:nlam]
  println()

  lam_est = [mode(lam[i] for lam in lams) for i in 1:num_cb_samples]

  for i in 1:num_cb_samples
    # Plot Z
    PlotUtils.plot_yz.plot_Z(Zmean, Wmean[i, :], lam_est[i], w_thresh=w_thresh)
    plt.savefig("$(imgdir)/Z$(i).pdf", bbox_inches="tight")
    plt.close()

    # plot Yi, lami
    plt.figure(figsize=(6, 6))
    PlotUtils.plot_yz.plot_y(y[i], Wmean[i, :], lam_est[i], vlim=vlim,
                             cm=PlotUtils.blue2red.cm(9), lw=lw,
                             fs_xlab=fs_y, fs_ylab=fs_y, fs_lab=fs_y,
                             fs_cbar=fs_ycbar, markernames=markernames)
    plt.savefig("$(imgdir)/y$(i).pdf", bbox_inches="tight")
    plt.close()
  end
end
