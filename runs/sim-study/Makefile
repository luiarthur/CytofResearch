SHELL = /bin/bash

.PHONY: all run-large run-small missmechsen postproc metrics 
.PHONY: createSimData


DATA_DIR = ../data
PATH_TO_SIMDATA_SMALL = $(DATA_DIR)/simdat-nfac500.bson
PATH_TO_SIMDATA_LARGE = $(DATA_DIR)/simdat-nfac5000.bson

createSimData: $(PATH_TO_SIMDATA_SMALL) $(PATH_TO_SIMDATA_LARGE)
	@echo "Created simulated data $(PATH_TO_SIMDATA_SMALL)"
	@echo "Created simulated data $(PATH_TO_SIMDATA_LARGE)"

$(PATH_TO_SIMDATA_SMALL) $(PATH_TO_SIMDATA_LARGE): createSimData.jl
	julia createSimData.jl
