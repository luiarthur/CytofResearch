#!/bin/bash

# Run this script with: sbatch submit-job.sh

#SBATCH -p 128x24       # Partition name
#SBATCH -J vb-cb-sens   # Job name
#SBATCH --mail-user=alui2@ucsc.edu
#SBATCH --mail-type=ALL
#SBATCH -o out/slurm-job.out # Name of stdout output file
#SBATCH -N 1                 # Total number of nodes requested (128x24/Instructional only)
#SBATCH -t 48:00:00          # Run Time (hh:mm:ss) - 48 hours (optional)
#SBATCH --mem=48G            # Memory to be allocated PER NODE

echo "SCRATCH_DIR: $SCRATCH_DIR"

AWS_BUCKET="s3://cytof-vb/vb-cb-psens"
RESULTS_DIR="results"

# Load these modules
module load R/R-3.6.1

# Make sure Mclust is installed
# You can install mclust if needed by first loading the module 
# as done above, and then in (the loaded version of) R:
#`install.packages('mclust')`.
julia -e 'import Pkg; Pkg.activate(joinpath(@__DIR__, "../../")); Pkg.build("RCall")'

echo "This is a healthy sign of life ..."
echo "This node has `nproc` processors."

# Make output directory.
mkdir -p results

# Run script.
NUM_PROCS=40
# julia run.jl $NUM_PROCS &> $(RESULTS_DIR)/log.txt &
julia run.jl &> $RESULTS_DIR/log.txt &

echo "Job submission time:"
date

echo "Jobs are now running. A message will be printed and emailed when jobs are done."
wait
echo "Jobs are completed."

# Send results
aws s3 sync $RESULTS_DIR $AWS_BUCKET --exclude '*.nfs'

echo "Job completion time:"
date
