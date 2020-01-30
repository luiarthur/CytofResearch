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
	@echo TODO

# Make metrics for run-cb (varying K)
metrics:
	@echo TODO

# Run CB analysis for various K
run-cb-fam: getcbdata preproc
	julia run_cb_fam.jl $(NPROC_CB) &> results/run_cb_fam.log &

# Kill all CB run jobs
kill-cb-runs:
	kill `cat results/run_cb_fam.log | grep -oP '(?<=Worker pids:).*'`
	kill `cat results/run_cb_fam.log | grep -oP '(?<=Master node pid:).*'`


# Run CB analysis for two more missing mechanisms, for the best K.
run-cb-fam-missmech: getcbdata preproc
	@echo TODO

# Preprocess transformed CB data
preproc: $(path_to_reduced_cb_data)

$(path_to_reduced_cb_data): $(path_to_cb_data) preprocess_cb_data.jl
	julia preprocess_cb_data.jl

