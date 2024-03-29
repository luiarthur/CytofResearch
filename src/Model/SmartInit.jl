# TODO: 
# Install mclust if necessary

function load_or_install_mclust()
  R"""
  if ("mclust" %in% installed.packages()) {
    library(mclust)
  } else {
    cat("Package `mclust` not found. Installing `mclust`...\n")
    install.packages("mclust")
  }
  """
end


function rangev(a, b; length::Int)
  return collect(range(a, b, length=length))
end

function gen_idx(N)
  I = length(N)
  upper_idx = cumsum(N)
  lower_idx = [1; upper_idx[1:end-1] .+ 1]
  return [lower_idx[i]:upper_idx[i] for i in 1:I]
end


function subsampleData(y::Matrix{T}, percentage) where {T <: Number}
  if 0 < percentage < 1
    N = size(y, 1)
    N_subsample = round(Int, N * percentage)
    idx_subsample = StatsBase.sample(1:N, N_subsample, replace=true)
    return y[idx_subsample, :]
  else
    println("Info: percentage ∉  (0, 1). Not subsampling.")
    return y
  end
end


function preimpute!(y::Matrix{T}, missMean::AbstractFloat,
                    missSD::AbstractFloat=0.2) where {T <: Number}
  num_missing = sum(isnan.(y))
  y[isnan.(y)] .= randn(num_missing) .- missMean
end


function smartInit(c::Constants, d::Data;
                   iterMax::Int=10, modelNames::String="VVI",
                   warn::Bool=true) where {T <: Number}

  if modelNames != "kmeans"
    load_or_install_mclust()
    Mclust = R"mclust::Mclust"
  else
    kmeans = R"kmeans"
  end

  y_imputed = deepcopy(d.y)
  I = d.I
  N = d.N
  J = d.J
  K = c.K
  L = c.L
  idx = gen_idx(N)

  # Mean of imputed values
  missMean = [c.beta[2, i] / (-2 * c.beta[1, i]) for i in 1:I]

  # Preimpute values
  for i in 1:I
    preimpute!(y_imputed[i], missMean[i])
  end

  if modelNames == "kmeans"
    clus = kmeans(vcat(y_imputed...), centers=K, iter=iterMax)
  else
    clus = Mclust(vcat(y_imputed...), G=K, modelNames=modelNames, warn=warn)
  end

  # Get order of class labels
  if modelNames == "kmeans"
    lam = [Int.(clus[:cluster])[idx[i]] for i in 1:I]
  else
    lam = [Int.(clus[:classification])[idx[i]] for i in 1:I]
  end
  lam = [Int8.(lam[i]) for i in 1:I]
  ord = [sortperm(lam[i]) for i in 1:I]

  # Get Z
  group_sizes = [sum(vcat(lam...) .== k) for k in 1:K]
  clus_sums = [sum(y_imputed[i][lam[i] .== k, :], dims=1)
               for k in 1:K, i in 1:I]
  clus_means = [sum(clus_sums[k, :]) / group_sizes[k] for k in 1:K]
  Z = Matrix{Bool}(vcat(clus_means...)' .> 0)

  # Get W
  W = [(sum(lam[i] .== k) + 1/K) / N[i] for i in 1:I, k in 1:K]

  # Get alpha
  alpha = (sum(Z) * K) / (J*K - sum(Z))

  # Get v
  # v = vec(mean(Z .+ (1.0 / J), dims=1))
  v = fill(alpha / (alpha + K), K)

  (m0, s0, _, _) = params(c.delta_prior[0])
  (m1, s1, _, _) = params(c.delta_prior[1])
  delta = Dict(false => rand(TruncatedNormal(m0, s0, 0, Inf), L[0]), 
               true  => rand(TruncatedNormal(m1, s1, 0, Inf), L[1]))

  # Get gam
  gam = [zeros(Int8, N[i], J) for i in 1:I]
  for i in 1:I
    for j in 1:J
      for n in 1:N[i]
        z = Z[j, lam[i][n]]
        mus_z = cumsum(delta[z]) * (-1) ^ (1 - z)
        gam[i][n, j] = argmin(abs.(y_imputed[i][n, j] .- mus_z))
      end
    end
  end

  # Get eta
  eta = Dict(Bool(z) => zeros(I, J, L[z]) for z in 0:1)

  for i in 1:I
    for j in 1:J
      counts = Dict(z => ones(L[z]) for z in 0:1)
      for n in 1:N[i]
        z = Z[j, lam[i][n]]
        l = gam[i][n, j]
        counts[z][l] += 1
      end
      eta[0][i, j, :] .= counts[0] / sum(counts[0])
      eta[1][i, j, :] .= counts[1] / sum(counts[1])
    end
  end

  # Get sig2
  sig2 = zeros(I)
  for i in 1:I
    for j in 1:J
      for n in 1:N[i]
        z = Z[j, lam[i][n]]
        l = gam[i][n, j]
        mus_z = cumsum(delta[z]) * (-1) ^ (1 - z)
        sig2[i] += (y_imputed[i][n, j] - mus_z[l]) ^ 2
      end
    end
    sig2[i] /= (N[i] * J)
  end

  eps = mean.(c.eps_prior)

  # Create State object
  state = State{Float64}()

  # Initialize State
  state.Z = Z
  state.delta = delta
  state.alpha = alpha
  state.v = v
  state.W = W
  state.sig2 = sig2
  state.eta = eta
  state.lam = lam
  state.gam = gam
  state.y_imputed = y_imputed
  state.eps = eps

  return state
end
