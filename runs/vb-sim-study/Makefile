SHELL = /bin/bash

.PHONY: all run postproc clean

path_to_small_simdata = "../data/simdat-nfac500.bson" 
path_to_large_simdata = "../data/simdat-nfac5000.bson"

all: run postproc

run:
	julia run.jl 10 $(path_to_small_simdata) "small"
	julia run.jl 10 $(path_to_large_simdata) "large"

postproc:
	julia post_process.jl $(path_to_small_simdata) "results/small" &
	julia post_process.jl $(path_to_large_simdata) "results/large" &

clean:
	rm -rf results/*
