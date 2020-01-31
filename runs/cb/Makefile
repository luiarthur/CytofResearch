SHELL = /bin/bash

.PHONY: all  getcbdata
.PHONY: run-cb-fam  run-cb-fam-missmech
.PHONY:	preproc  postproc  metrics

# TODO:
# - [X] getcbdata
# - [ ] run-cb-fam
# - [ ] run-cb-fam-missmech
# - [X] preproc
# - [ ] postproc
# - [ ] metrics

### Make variables ###
data_dir = ../data

cb_transformed_data_url = https://raw.githubusercontent.com/luiarthur/cytof-data/master/data/cb/cb_transformed.csv

path_to_cb_data = $(data_dir)/cb_transformed.csv

path_to_reduced_cb_data = $(data_dir)/cb_transformed_reduced.csv

# Number of cores to use for CB analysis
NPROC_CB = 11

### Make commands ###

# Download transformed CB data.
# For data info, see: https://github.com/luiarthur/cytof-data
getcbdata: $(path_to_cb_data)
	@echo transformed cb data is in $(path_to_cb_data)

$(path_to_cb_data):
	wget $(cb_transformed_data_url) -O $(path_to_cb_data)

# Post process results
postproc:
	julia postprocess_cb_fam.jl

# Make metrics for run-cb (varying K)
# Make metrics for missmech vs LPML, DIC
metrics:
	julia metrics.jl

# Run CB analysis for various K on mm0
# Run CB analysis for best K (21) on mm1 and mm2
run-cb-fam: getcbdata preproc
	julia run_cb_fam.jl $(NPROC_CB) `seq -s ',' 3 3 33` 0 \
		&> results/run_cb_fam_mm0.log &
	julia run_cb_fam.jl 1 21 1 &> results/run_cb_fam_mm1.log &
	julia run_cb_fam.jl 1 21 2 &> results/run_cb_fam_mm2.log &

# Kill all CB run jobs
kill-cb-runs:
	kill `cat results/run_cb_fam_mm0.log | grep -oP '(?<=Worker pids:).*'`
	kill `cat results/run_cb_fam_mm0.log | grep -oP '(?<=Master node pid:).*'`
	kill `cat results/run_cb_fam_mm1.log | grep -oP '(?<=Worker pids:).*'`
	kill `cat results/run_cb_fam_mm1.log | grep -oP '(?<=Master node pid:).*'`
	kill `cat results/run_cb_fam_mm2.log | grep -oP '(?<=Worker pids:).*'`
	kill `cat results/run_cb_fam_mm2.log | grep -oP '(?<=Master node pid:).*'`


# Preprocess transformed CB data
preproc: $(path_to_reduced_cb_data)

$(path_to_reduced_cb_data): $(path_to_cb_data) preprocess_cb_data.jl
	julia preprocess_cb_data.jl

