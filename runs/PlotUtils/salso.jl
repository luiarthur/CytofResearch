# NOTE: Based on https://rdrr.io/cran/sdols/ by David B. Dahl.

"""
Create pairwise allocation matrix
"""
function pairwiseallocmat(Z, W, i)
  J, K = size(Z)
  A = zeros(J, J)
  for r in 1:J
    for c in 1:J
      for k in 1:K
        if Z[r, k] == 1 && Z[c, k] == 1
          A[r, c] += W[i, k]
          A[c, r] += W[i, k]
        end
      end
    end
  end

  return A
end

function estimate_ZWi_index(Zs, Ws, i)
  As = [pairwiseallocmat(z, w, i) for (z, w) in zip(Zs, Ws)]

  Amean = mean(As)
  mse = [mean((A - Amean) .^ 2) for A in As]

  return argmin(mse)
end
