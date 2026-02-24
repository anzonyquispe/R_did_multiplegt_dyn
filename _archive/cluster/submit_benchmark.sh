#!/bin/bash
#SBATCH --job-name=did_benchmark
#SBATCH --output=benchmark_%j.out
#SBATCH --error=benchmark_%j.err
#SBATCH --time=04:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --partition=standard

# =============================================================================
# DID Benchmark Job Script for Notre Dame CRC
# =============================================================================

echo "=========================================="
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "=========================================="

# Load required modules
# Note: Check available modules with 'module avail R' and 'module avail gcc'
module purge
module load R/4.3.1      # or latest available: module avail R
module load gcc/11.3.0   # needed for compiling packages

# Set R library path to your personal library
export R_LIBS_USER=$HOME/R/libs
mkdir -p $R_LIBS_USER

# Set number of threads for polars
export POLARS_MAX_THREADS=$SLURM_CPUS_PER_TASK

echo "R_LIBS_USER: $R_LIBS_USER"
echo "POLARS_MAX_THREADS: $POLARS_MAX_THREADS"

# Set project root
export PROJECT_ROOT=$HOME/R_didgt_polars

# Change to the cluster directory
cd $PROJECT_ROOT/cluster

# Run the benchmark
echo ""
echo "Starting benchmark..."
echo "=========================================="

Rscript benchmark_wolfers_cluster.R

echo ""
echo "=========================================="
echo "Job finished at: $(date)"
echo "=========================================="
