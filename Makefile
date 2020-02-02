SHELL = /bin/bash

.PHONY: all reproduce clean-data recreate-all-data
.PHONY: run-cb run-flowsom run-simstudy run-vb-cb run-vb-simstudy

### Make commands ###
all: reproduce

# Reproduce results (figures, files, etc.)
reproduce: recreate-all-data \
	         run-cb \
					 run-flowsom \
					 run-simstudy \
					 run-vb-cb \
					 run-vb-simstudy

# Recreate data used in paper
# - CB Data (transformed and pre-processed)
# - Simulated data I (small)
# - Simulated data II (large)
recreate-all-data:
	@cd runs/cb && make getcbdata --no-print-directory
	@cd runs/cb && make preproc --no-print-directory
	@cd runs/sim-study && make createSimData --no-print-directory

# Remove data used in paper. (In case something goes wrong.)
clean-data:
	@echo "Removing CB and simulated data in `runs/data/`"
	rm -f runs/data/*

# Run all CB alanyses with MCMC (including missing data mechanism sensitivity
# analysis). If run on 11 cores in parallel, the model with the largest K (33)
# takes about a month to complete on the processor listed in the paper.
run-cb:
	cd runs/cb && make all  --no-print-directory

# Run all flowsom analysis (for CB and simulated data)
# This completes in 5 - 10 minutes. 
run-flowsom:
	cd runs/flowsom && make all  --no-print-directory
	
# Run all simulation studies for MCMC
# If 20 cores are available, this takes about 3 weeks.
run-simstudy:
	cd runs/sim-study && make all  --no-print-directory

# Run CB analysis (with various random seeds) for VB 
# If 10 cores are available, this takes less than 1 day.
run-vb-cb:
	cd runs/vb-cb && make all  --no-print-directory

# Run sim studies (with various random seeds) for VB 
# If 20 cores are available, this takes less than 1 day.
run-vb-simstudy:
	cd runs/vb-sim-study && make all  --no-print-directory
