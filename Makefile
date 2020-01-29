SHELL = /bin/bash

.PHONY: all reproduce clean-data recreate-all-data run-cb

### Make commands ###
all: reproduce

# Reproduce results (figures, files, etc.)
reproduce: recreate-all-data \
	         run-cb
	@echo TODO

# Recreate data used in paper
# - CB Data
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

run-cb:
	@echo "Running all CB analyses." \
		@cd runs/cb && make run-cb-fam \
		@cd runs/cb && make run-cb-fam-missmech \
		@cd runs/cb && make run-cb-vb \
		@cd runs/cb && make run-cb-flowsom 

