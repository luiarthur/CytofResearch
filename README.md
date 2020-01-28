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

## Put ACC Form here
