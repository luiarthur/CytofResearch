function update_Z_v2!(s::State, c::Constants, d::Data, tuners::Tuners,
                      sb_ibp::Bool; use_repulsive::Bool=false)
  if 0.1 > rand()
    # update Z marginalizing over lam and gam
    update_Z_marg_lamgam!(s, c, d, sb_ibp, use_repulsive=use_repulsive)
  else
    update_Z!(s, c, d, sb_ibp, use_repulsive=use_repulsive)
  end
end

function update_Z_marg_lamgam!(j::Int, k::Int,
                               A::Vector{Vector{Float64}},
                               B0::Vector{Matrix{Float64}},
                               B1::Vector{Matrix{Float64}},
                               s::State, c::Constants, d::Data, sb_ibp::Bool;
                               use_repulsive::Bool=false)
  v = sb_ibp ? cumprod(s.v) : s.v
  Z0 = deepcopy(s.Z)
  Z0[j, k] = false 
  lp0 = MCMC.log1m(v[k]) + log_dmix_nolamgam(Z0, A, B0, B1, s, c, d)

  Z1 = deepcopy(s.Z)
  Z1[j, k] = true 
  lp1 = log(v[k]) + log_dmix_nolamgam(Z1, A, B0, B1, s, c, d)

  if use_repulsive
    lp0 += log_penalty_repFAM(k, Z0, c.similarity_Z)
    lp1 += log_penalty_repFAM(k, Z1, c.similarity_Z)
  end

  p1_post = 1 / (1 + exp(lp0 - lp1))
  new_Zjk_is_one = p1_post > rand()
  s.Z[j, k] = new_Zjk_is_one
end

function update_Z_marg_lamgam!(s::State, c::Constants, d::Data, sb_ibp::Bool;
                               use_repulsive::Bool=false)
  # Precompute A, B0, B1
  A = [[logdnoisy(i, n, s, c, d) for n in 1:d.N[i]] for i in 1:d.I]
  B0 = [[logdmixture(0, i, n, j, s, c, d) for n in 1:d.N[i], j in 1:d.J]
        for i in 1:d.I]
  B1 = [[logdmixture(1, i, n, j, s, c, d) for n in 1:d.N[i], j in 1:d.J]
        for i in 1:d.I]

  for j in 1:d.J
    for k in 1:c.K
      update_Z_marg_lamgam!(j, k, A, B0, B1, s, c, d, sb_ibp,
                            use_repulsive=use_repulsive)
    end
  end
end
