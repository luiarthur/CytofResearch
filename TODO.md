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
- [ ] Figure 4
    - Simulation 1: FlowSOM y sorted.
- [ ] Figure 7
    - CB FAM: FlowSOM. y sorted, each cluster sizes.
- [X] Table 1
    - Simulation 1: True Z & W
- [X] Figure 2
    - Simulation 1: LPML, DIC, Calibration metric
- [X] Figure 3
    - Simulation 1: Z hat, y sorted
- [X] Figure 5
    - CB FAM: LPML, DIC, Calibration metric
- [X] Figure 6
    - CB FAM: Z hat, y sorted

## Supplementary Tables / Figures
- [ ] Figure 2:
    - ADVI Sim 1: Z, y sorted
- [ ] Figure 7:
    - Sim 2 ADVI: Z, y sorted
- [ ] Figure 14:
    - CB missmech 0 ADVI. y, Z
- [ ] Figure 10:
    - Sim 2 FlowSOM
- [X] Figure 11:
    - TSNE CB
- [X] Table 6:
    - beta for CB data
- [x] Figure 12:
    - CB missmech 1 MCMC. y, Z
- [x] Figure 13:
    - CB missmech 2 MCMC. y, Z
- [X] Table 1:
    - MCMC Sim 1: missmech vs LPML, DIC
- [X] Table 3:
    - MCMC Sim 2: missmech vs LPML, DIC
- [X] Table 5:
    - MCMC CB: missmech vs LPML, DIC
- [X] Figure 3:
    - Sim 1 missmech 1 MCMC.
- [X] Figure 4:
    - Sim 1 missmech 2 MCMC.
- [X] Table 2:
    - Sim 2 True Z & W
- [X] Figure 5:
    - Sim 2 MCMC: LPML, DIC, Calibration metric
- [X] Figure 6:
    - Sim 2 MCMC: Z, y sorted
- [X] Figure 8:
    - Sim 2 missmech 1 MCMC.
- [X] Figure 9:
    - Sim 2 missmech 2 MCMC.


[1]: https://julialang.github.io/Pkg.jl/v1/creating-packages/#Adding-a-build-step-to-the-package-1
