SHELL = /bin/bash

.PHONY: all run preproc sendoutput

# NOTE: Change accordingly.
BATCHSIZE = 2000
# BATCHSIZE = 500

# Experiment name
EXP_NAME = vb-cb-psens-bs$(BATCHSIZE)

# Results dir
RESULTS_DIR = results/$(EXP_NAME)

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
	rm -f $(RESULTS_DIR)/best_seeds.txt
	rm -rf $(RESULTS_DIR)/bundle
	julia post_process.jl > $(RESULTS_DIR)/best_seeds.txt
	. bundle.sh $(RESULTS_DIR)

bundle:
	. bundle.sh $(RESULTS_DIR)
