SHELL = /bin/bash

.PHONY: all run-sims-default-missmech missmechsen postproc metrics runsims
.PHONY: createSimData


DATA_DIR = ../data
PATH_TO_SIMDATA_SMALL = $(DATA_DIR)/simdat-nfac500.bson
PATH_TO_SIMDATA_LARGE = $(DATA_DIR)/simdat-nfac5000.bson

createSimData: $(PATH_TO_SIMDATA_SMALL) $(PATH_TO_SIMDATA_LARGE)
	@echo "Created simulated data $(PATH_TO_SIMDATA_SMALL)"
	@echo "Created simulated data $(PATH_TO_SIMDATA_LARGE)"

$(PATH_TO_SIMDATA_SMALL) $(PATH_TO_SIMDATA_LARGE): createSimData.jl
	julia createSimData.jl

run-sims-default-missmech:
	julia run_sim_study.jl \
		19 \
		"2,3,4,5,6,7,8,9" \
		"2,4,6,8,10,12,14,16,18,20" \
		"0.00,0.25,0.50" \
		"mm0" &> results/run-sim-study.log &

missmechsen:
	@echo "Do simulations with missing mechanism I:"
	julia run_sim_study.jl \
		2 \
		"5" \
		"10" \
		"0.0,0.2,0.4" \
		"mm1" &> results/run-sim-study-mm1.log &
	@echo "Do simulations with missing mechanism II:"
	julia run_sim_study.jl \
		2 \
		"5" \
		"10" \
		"0.00,0.15,0.30" \
		"mm2" &> results/run-sim-study-mm2.log &

runsims:
	make run-sims-default-missmech --no-print-directory &
	make missmechsen --no-print-directory &

kill-sim-runs:
	kill `cat results/run-sim-study*.log | grep -oP '(?<=Worker pids:).*'`
	kill `cat results/run-sim-study*.log | grep -oP '(?<=Master node pid:).*'`

