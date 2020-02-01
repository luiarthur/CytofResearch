# using CytofResearch
# using Distributions
# using Flux, Flux.Tracker
include(joinpath(@__DIR__, "util.jl"))
include(joinpath(@__DIR__, "logprob_lam.jl"))

function sample_lam(state::CytofResearch.VB.StateMP, y::Vector{Matrix{Float64}},
                    c::CytofResearch.VB.Constants)
  _, s, ys, _ = CytofResearch.VB.rsample(state, y, c)
  lp_lam= logprob_lam(data(s), Tracker.data.(ys), c)
  lam = [[CytofResearch.MCMC.wsample_logprob(lp_lam[i][n, :])
          for n in 1:c.N[i]] for i in 1:c.I]

  # Relabel noisy class as 0
  for i in 1:c.I
    for n in 1:c.N[i]
      if lam[i][n] > c.K
        lam[i][n] = 0
      end
    end
  end

  return Vector{Int8}.(lam)
end


VV = Vector{Vector{I}} where I
VVV = Vector{VV{I}}  where I

function lam_f(lam_samps::VVV{T}, i::Integer, n::Integer, f::Function) where {T <: Integer}
  B = length(lam_samps)
  return f(lam_samps[b][i][n] for b in 1:B)
end

function lam_f(lam_samps::VVV{T}, f::Function) where {T <: Integer}
  I = length(lam_samps[1])
  N = length.(lam_samps[1])
  B = length(lam_samps)

  return [[lam_f(lam_samps, i, n, f) for n in 1:N[i]] for i in 1:I]
end
