SHELL = /bin/bash

.PHONY: all reproduce clean-data

### Make commands ###
all: reproduce

# Reproduce results (figures, files, etc.)
reproduce: recreate-all-data
	@echo TODO

# Recreate data used in paper
# - CB Data
# - Simulated data I (small)
# - Simulated data II (large)
recreate-all-data:
	@cd runs/cb && make getcbdata -s
	@cd runs/sim-study && make createSimData --no-print-directory

# Remove data used in paper. (In case something goes wrong.)
clean-data:
	@echo "Removing CB and simulated data in `runs/data/`"
	rm -f runs/data/*
