
"""
Fits the feature allocation model (FAM) as shown in the paper via MCMC.

# Arguments <defaults>:

- `init::State`: Inital state.

- `c::Constants`: Model constants.

- `d::Data`: Model data.

- `nmcmc::Int`<1000>: Number of mcmc iterations to do post burn-in.
   If `thins` is not the default, the number of samples obtained for each
   `monitor` may not be `nmcmc`.

- `nburn::Int`<1000>: Number of iterations for burn in.

- `monitors::Vector{Vector{Symbol}}`
   <[[:Z, :lam, :W], :v, :sig2, :delta, :alpha, :eta, :eps]]>:
   A list of monitors, where each monitor is a list of symbols.  If a symbol
   appears in a monitor, it is stored and returned at the end of the MCMC. The
   symbols have to correspond to fields in the `State` object.

- `fix::Vector{Symbol}`<[]>: A list of parameters (which should be a field in the
   `State` object) to fix at the initial value. (i.e.  if :Z appears in `fix`,
   then Z is never updated.) This is for debugging purposes.

- `thins::Vector{Int}<[1]>`: A list of integers with the same length as
   monitors. The first integer is the factor to thin the first group of
   parameters (monitor). So if `thins[1]`=2 and `nmcmc`=2000, then 
   1000=`nmcmc/thins[1]` samples will be obtained for `monitors[1]`.
                        
- `thin_dden::Int`<1>: Samples of density-estimates of the data are stored.
   This argument is to thin the samples.

- `printFreq::Int`<0>: Print frequency. Defaults to 0 => prints every 10%.
  turn off printing by setting to -1. If `printFreq` = 2, loglikelihood and
  time will be printed every 2 mcmc iterations.

- `computeDIC::Bool`<false>: Whether to compute DIC.

- `computeLPML::Bool`:<false>: Whether to compute LPML.

- `computedden::Bool`<false>: Whether to compute data density estimates.

- `sb_ibp::Bool`<false>: Whether to use the stick-break construction of IBP.
  If `false`, the regular IBP is used, and a Gibbs step is available. 
  Otherwise, an anto-tuned metropolis step is used.

- `use_repulsive::Bool`<false>: Whether to use the repulsive FAM.

- `joint_update_Z::Bool`<false>: Whether to jointly update elements in Z.

- `verbose::Bool`<1>: Verbosity of output. 0 for bare minimum to none.
  1 for basic output. Greater than 1 for full on debug mode.
"""
function cytof_fit(init::State, c::Constants, d::Data;
                   nmcmc::Int=1000, nburn::Int=1000, 
                   monitors=[[:Z, :lam, :W, :v,
                              :sig2, :delta, :alpha, 
                              :eta, :eps]],
                   fix::Vector{Symbol}=Symbol[],
                   thins::Vector{Int}=[1],
                   thin_dden::Int=1,
                   printFreq::Int=0,
                   computeDIC::Bool=false, computeLPML::Bool=false,
                   computedden::Bool=false,
                   sb_ibp::Bool=false,
                   use_repulsive::Bool=false, joint_update_Z::Bool=false,
                   verbose::Int=1)

  if verbose >= 1
    fixed_vars_str = join(fix, ", ")
    if fixed_vars_str == ""
      fixed_vars_str = "nothing"
    end
    printlnflush("fixing: $fixed_vars_str")
    printlnflush("Use stick-breaking IBP: $(sb_ibp)")
  end

  @assert printFreq >= -1
  if printFreq == 0
    numPrints = 10
    printFreq = Int(ceil((nburn + nmcmc) / numPrints))
  end


  y_tuner = begin
    dict = Dict{Tuple{Int, Int, Int}, MCMC.TuningParam{Float64}}()
    for i in 1:d.I
      for n in 1:d.N[i]
        for j in 1:d.J
          if d.m[i][n, j] == 1
            dict[i, n, j] = MCMC.TuningParam(1.0)
          end
        end
      end
    end
    dict
  end

  tuners = Tuners(y_imputed=y_tuner, # yinj, for inj s.t. yinj is missing
                  Z=MCMC.TuningParam(MCMC.sigmoid(c.probFlip_Z, a=0.0, b=1.0)),
                  v=[MCMC.TuningParam(1.0) for k in 1:c.K])

  # Loglike
  loglike = Float64[]

  function printMsg(iter::Int, msg::String)
    if printFreq > 0 && iter % printFreq == 0
      printflush(msg)
    end
  end

  # Instantiate (but not initialize) CPO stream
  if computeLPML
    cpoStream = MCMC.CPOstream{Float64}()
  end

  # DIC
  if computeDIC
    local tmp = DICparam(p=deepcopy(d.y),
                         mu=deepcopy(d.y),
                         sig=[zeros(Float64, d.N[i]) for i in 1:d.I],
                         y=deepcopy(d.y))
    dicStream = MCMC.DICstream{DICparam}(tmp)

    function updateParams(d::MCMC.DICstream{DICparam}, param::DICparam)
      d.paramSum.p += param.p
      d.paramSum.mu += param.mu
      d.paramSum.sig += param.sig
      d.paramSum.y += param.y
      return
    end

    function paramMeanCompute(d::MCMC.DICstream{DICparam})::DICparam
      return DICparam(d.paramSum.p ./ d.counter,
                      d.paramSum.mu ./ d.counter,
                      d.paramSum.sig ./ d.counter,
                      d.paramSum.y ./ d.counter)
    end

    function loglikeDIC(param::DICparam)::Float64
      ll = 0.0

      for i in 1:d.I
        for j in 1:d.J
          for n in 1:d.N[i]
            y_inj_is_missing = (d.m[i][n, j] == 1)

            # NOTE: This is Conditional DIC, which treats missing values
            # as additional parameters. The p(m_obs | y_obs, beta) term
            # is excluded because it is a constant due to beta being fixed.
            # See: http://www.bias-project.org.uk/papers/DIC.pdf
            #
            # NOTE: Refer to `../compute_loglike.jl` for reasoning.
            if y_inj_is_missing
              # Compute p(m_inj | y_inj, theta) term.
              ll += log(param.p[i][n, j])
            else
              # Compute p(y_inj | theta) term.
              ll += logpdf(Normal(param.mu[i][n, j], param.sig[i][n]),
                           param.y[i][n, j])
            end
          end
        end
      end

      return ll
    end

    # FIXME: Doesn't work for c.noisyDist not Normal
    function convertStateToDicParam(s::State)::DICparam
      p = [[prob_miss(s.y_imputed[i][n, j], c.beta[:, i])
            for n in 1:d.N[i], j in 1:d.J] for i in 1:d.I]

      mu = [[s.lam[i][n] > 0 ? mus(i, n, j, s, c, d) : 0.0 
             for n in 1:d.N[i], j in 1:d.J] for i in 1:d.I]

      sig = [[s.lam[i][n] > 0 ? sqrt(s.sig2[i]) : std(c.noisyDist)
              for n in 1:d.N[i]] for i in 1:d.I]

      y = deepcopy(s.y_imputed)

      return DICparam(p, mu, sig, y)
    end
  end


  dden = Matrix{Vector{Float64}}[]

  function update!(s::State, iter::Int, out)
    update_state!(s, c, d, tuners, loglike, fix, use_repulsive,
                  joint_update_Z, sb_ibp)

    if computedden && iter > nburn && (iter - nburn) % thin_dden == 0
      append!(dden,
              [[datadensity(i, j, s, c, d) for i in 1:d.I, j in 1:d.J]])
    end

    if computeLPML && iter > nburn
      # Inverse likelihood for each data point
      like = [[compute_like(i, n, s, c, d) for n in 1:d.N[i]] for i in 1:d.I]

      # Update (or initialize) CPO
      MCMC.updateCPO(cpoStream, vcat(like...))

      # Add to printMsg
      printMsg(iter, " -- LPML: $(MCMC.computeLPML(cpoStream))")
    end

    if computeDIC && iter > nburn
      # Update DIC
      MCMC.updateDIC(dicStream, s, updateParams,
                     loglikeDIC, convertStateToDicParam)

      # Add to printMsg
      printMsg(iter, " -- DIC: $(MCMC.computeDIC(dicStream, loglikeDIC,
                                                 paramMeanCompute))")
    end

    printMsg(iter, "\n")
  end

  if isinf(compute_loglike(init, c, d, normalize=true))
    printlnflush("Warning: Initial state yields likelihood of zero.")
    msg = """
    It is likely the case that the initialization of missing values
    is not consistent with the provided missing mechanism. The MCMC
    will almost certainly reject the initial values and sample new
    ones in its place.
    """
    printlnflush(join(split(msg), " "))
  else
    printlnflush()
  end

  out, lastState = MCMC.gibbs(init, update!, monitors=monitors,
                              thins=thins, nmcmc=nmcmc, nburn=nburn,
                              printFreq=printFreq,
                              loglike=loglike,
                              printlnAfterMsg=!(computeDIC || computeLPML))

  # Create dictionary to store results
  results = Dict{Symbol, Any}()

  results[:out] = out  # monitors
  results[:lastState] = lastState
  results[:loglike] = loglike
  results[:c] = c
  results[:init] = init

  if computeDIC || computeLPML
    LPML = computeLPML ? MCMC.computeLPML(cpoStream) : NaN
    Dmean, pD = computeDIC ? MCMC.computeDIC(dicStream,
                                             loglikeDIC,
                                             paramMeanCompute,
                                             return_Dmean_pD=true) : (NaN, NaN)
    metrics = Dict(:LPML => LPML,
                   :DIC => Dmean + pD,
                   :Dmean => Dmean,
                   :pD => pD)
    printlnflush()
    printlnflush("metrics:")
    for (k, v) in metrics
      printlnflush("$k => $v")
    end

    results[:metrics] = metrics
  end

  if computedden
    results[:dden] = dden
  end

  return results
end
