# CytofResearch
Research code for CyTOF data analysis using Bayesian feature allocation model.

## Emulating the environment used for producing results
In Julia, run the following.

```julia
empty!(LOAD_PATH)  # Prevents julia from finding locally installed libraries
                   # for the current session.
push!(LOAD_PATH,
      "@",         # Adds the active directory to the load path.
      "@stdlib")   # Adds the standard library to the load path.

import Pkg
Pkg.activate(".")  # Tells julia to treat this as the working environment.
Pkg.instantiate()  # Tells julia to install packages in this environment.
                   # Julia uses the `Manifest.toml` and `Project.toml` to
                   # recreate the environment (i.e. install required packages,
                   # etc.).

using CytofResearch
```

# Author Contributions for A Bayesian Feature Allocation Model for Identification of Cell Subpopulations Using Cytometry Data

## Data

### Abstract
Three datasets are presented in this work: (1) a  small-sized synthetic
dataset, (2) a large-sized synthetic dataset, and (3) a cord blood (CB) dataset
provided by our collaborators at MD Anderson Cancer Center. The synthetic
datasets are simulated from the model and provide ground truth to study model
performance, as our model performs unsupervised learning. The CB cell-surface
marker expression data consists of three samples, each having the same markers
(columns), but different number of cells (rows). The data file is
comma-separated. The cutoffs for each sample and marker are listed in a
separate file. More details are provided on the GitHub repository where it
resides. (See next section.)

### Availability
The real cord blood (CB) data used in this work is publicly available at the
GitHub repository: https://github.com/luiarthur/cytof-data. The data can either
be cloned as a Git repository, or downloaded as a compressed file. The
`README.md` in the root directory describes the structure of the repository.

### Description
- Author permissions: 
    - We have received permission from our collaborators to make the CB data
      used in this work publicly available.
- Licensing information or terms of use:
    - MIT License
- Link to data/repository
    - The data and codes are available from
    - https://github.com/luiarthur/cytof-data.
- Data provenance, including identifier or link to original data if different
  than above
    - The repository contains original CB data, the transformed CB data, and
      the python script used to obtain the transformed data used in the model.
- File format
    - Cutoff values, marker expression levels, and transformed marker
      expression levels used in CB data are in comma-separated files, with
      columns headers.  Each sample is indexed by a number, but was also given
      a name. These names (which are not relevant to the model) are included in
      a text file.
- Metadata (including data dictionary)
    - Metadata and data dictionary are included in the repository.
- Version information
    - Git branch: master
    - Git commit hash: `ac1d4a02135aca8ff96d75973e63d9a7d45a9884`

## Code
### Abstract
A Julia package (`CytofResearch`) was created for this project, and resides at
https://github.com/luiarthur/cytofresearch. Code used for simulation studies
and the CB data analysis are also included in the repository. 

### Description
 - How delivered: Julia package. The Julia package is not currently available
   on the Julia General Registry, but it can be cloned directly from GitHub.
   The package state (exact versions of library dependencies) are listed in the
   `Project.toml` and `Manifest.toml` files in the root directory. Hence, the
   package state can be recreated in Julia. (See
   https://julialang.github.io/Pkg.jl/v1/environments/#Using-someone-else's-project-1)
- Licensing information: MIT License
- Link to code/repository: https://github.com/luiarthur/cytofresearch
- Version information:
    - Git branch: master
    - Git commit hash: `8e3107315558c4baeb07885b62d635ccdf81013d`
- Release: v0.2.0
- Supporting software requirements
- Julia v1.0 or above
    - All Julia library dependencies are in the environment files
      (`Project.toml` and `Manifest.toml`).
    - The following software / libraries are not required for Julia, but are
      used in this work for graphing, comparing our method to existing methods
      implemented outside of Julia, and for calling libraries not readily
      available in Julia
        - R >= 3.0.0
            - `MClust` >= 5.4.2 (for MCMC initialization)
            - `flowCore` >= 1.44.2 (for existing method)
            - `FlowSOM` >= 1.14.1 (for existing method)
        - Python 3.6 or above
            - `matplotlib` >= 3.1.0 (for graphing)
            - `seaborn` >= 0.9.0 (for graphing)
            - `numpy` >= 1.17.3
            - `pandas` >= 0.24.2
            - `sklearn` >= 0.21.3

### Additional Information
- Hardware requirements: All computations were done on an interactive  Linux
  server with four Intel Xeon E5-4650 processors (8 cores, 2 threads per core)
  and 512 GB of random access memory. Though the computations for one model run
  for the CB data can reasonably be done via variational inference on a machine
  with 16 GB RAM and compute-optimized processors.
- UUID (for CytofResearch): b02177ca-416e-11ea-1c5f-9999da4b2093


## Instructions for Use
### Reproducibility
- The `Makefile` at the root of this repository contains commands to
  recreate results from the paper. Typing `make all` at the root of the repository
  (in a terminal) will start the process of running each simulation study / real
  data analysis.
- Alternatively, 
    - `make run-cb` reproduces the results for the MCMC CB analysis. If 13 CPU
      cores are available, this task can be completed in 1 month.
    - `make run-simstudy` reproduces the results for the MCMC simulation
      studies. If 21 cores are available, this task can be completed in 3
      weeks.
    - `make run-flowsom` reproduces the results for the flowsom simulation
      studies and CB analysis. This can be done with one processor in under 10
      minutes.
    - `make vb-cb` reproduces the results for the variational inference CB
      analysis for 10 random seeds (starting values). If 10 cores are available
      this task can be completed in 8-12 hours.
    - `make vb-simstudy` reproduces the results for the variational inference
      simulation studies for 10 random seeds (starting values). If 10 cores are
      available this task can be completed in 8-12 hours.
- All computations in this project were performed on an interactive Linux
  server with four Intel Xeon E5-4650 cores and 512 GB of random access memory.
  This project can not feasibly be replicated on a standard laptop / desktop.
  However, the computations for one model run for the CB data via variational
  inference can reasonably be done on a desktop with 16 GB RAM and
  compute-optimized processors.

### Installing CytofResearch as a package
The CytofResearch Git repository can be installed as a Julia package. To
install:
1. Launch a julia console in a terminal:
2. Enter package mode by typing `]`, followed by the return key
3. Type: `add https://github.com/luiarthur/CytofResearch` followed by the return key
4. To uninstall the package, type `remove CytofResearch` followed by the return key

