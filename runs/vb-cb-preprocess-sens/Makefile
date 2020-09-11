SHELL = /bin/bash

.PHONY: all run preproc sendoutput

# Experiment name
EXP_NAME = vb-cb-psens

# Results dir
RESULTS_DIR = results

# AWS bucket
AWS_BUCKET = s3://cytof-vb/$(EXP_NAME)

# This assumes that `make getcbdata` was run previously in `../cb`
preproc:
	julia preprocess_sens.jl

sendoutput:
	aws s3 sync $(RESULTS_DIR) $(AWS_BUCKET) --exclude '*.nfs'

getalloutput:
	aws s3 sync $(AWS_BUCKET) $(RESULTS_DIR) --exclude '*.nfs'

getoutput:
	aws s3 sync $(AWS_BUCKET) $(RESULTS_DIR) \
		--exclude '*.nfs' \
		--exclude "*/output.bson"

postproc:
	rm -f results/best_seeds.txt
	julia post_process.jl > results/best_seeds.txt
