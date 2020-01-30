# TODO
Add a [build step][1] to install R / python dependencies.

## Include
- [ ] CB runs and plots
    - [ ] K: 3, 6, ..., 33
    - [ ] missmech-0, missmech-1, missmech-2
- [ ] FlowSOM runs and plots
    - [ ] CB
    - [ ] sim-small
    - [ ] sim-large
- [ ] MCMC
    - [ ] sim-small
    - [ ] sim-large
- [ ] VB
    - [ ] CB
    - [ ] sim-small
    - [ ] sim-large

## Things to implement
- make_yz
- make_metrics
    - LPML
    - DIC
    - Calibration metric

## Main Tables / Figures
- [ ] Table 1
    - Simulation 1: True Z & W
- [ ] Figure 2
    - Simulation 1: LPML, DIC, Calibration metric
- [ ] Figure 3
    - Simulation 1: Z hat, y sorted
- [ ] Figure 4
    - Simulation 1: FlowSOM y sorted.
- [ ] Figure 5
    - CB FAM: LPML, DIC, Calibration metric
- [ ] Figure 6
    - CB FAM: Z hat, y sorted
- [ ] Figure 7
    - CB FAM: FlowSOM. y sorted, each cluster sizes.

## Supplementary Tables / Figures
- [ ] Figure 2:
    - ADVI Sim 1: Z, y sorted
- [ ] Table 1:
    - MCMC Sim 1: missmech vs LPML, DIC
- [ ] Figure 3:
    - Sim 1 missmech 1 MCMC.
- [ ] Figure 4:
    - Sim 1 missmech 2 MCMC.
- [ ] Table 2:
    - Sim 2 True Z & W
- [ ] Figure 5:
    - Sim 2 MCMC: LPML, DIC, Calibration metric
- [ ] Figure 6:
    - Sim 2 MCMC: Z, y sorted
- [ ] Figure 7:
    - Sim 2 ADVI: Z, y sorted
- [ ] Table 3:
    - MCMC Sim 2: missmech vs LPML, DIC
- [ ] Figure 8:
    - Sim 2 missmech 1 MCMC.
- [ ] Figure 9:
    - Sim 2 missmech 2 MCMC.
- [ ] Figure 10:
    - Sim 2 FlowSOM
- [ ] Figure 11:
    - TSNE CB
- [ ] Table 5:
    - MCMC CB: missmech vs LPML, DIC
- [ ] Table 6:
    - beta for CB data
- [ ] Figure 12:
    - CB missmech 1 MCMC. y, Z
- [ ] Figure 13:
    - CB missmech 1 MCMC. y, Z
- [ ] Figure 14:
    - CB missmech 0 ADVI. y, Z


[1]: https://julialang.github.io/Pkg.jl/v1/creating-packages/#Adding-a-build-step-to-the-package-1
