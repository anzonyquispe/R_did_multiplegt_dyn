# Running DID Benchmark on Notre Dame CRC Cluster

## Overview

This guide explains how to run the `benchmark_wolfers_complete.R` script on the Notre Dame Center for Research Computing (CRC) cluster.

## Step 1: Connect to the Cluster

```bash
# SSH into the CRC cluster
ssh your_netid@crcfe01.crc.nd.edu
```

## Step 2: Upload Your Project

### Option A: Using scp (from your local machine)
```bash
# From your local terminal (not on the cluster)
cd /Users/anzony.quisperojas/Documents/GitHub
scp -r R_didgt_polars your_netid@crcfe01.crc.nd.edu:~/
```

### Option B: Using rsync (recommended for updates)
```bash
# From your local terminal
rsync -avz --progress \
  /Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars \
  your_netid@crcfe01.crc.nd.edu:~/
```

### Option C: Clone from GitHub (if your repo is on GitHub)
```bash
# On the cluster
cd ~
git clone https://github.com/YOUR_USERNAME/R_didgt_polars.git
```

## Step 3: Set Up R Environment

### 3.1 Start an Interactive Session (for package installation)
```bash
# Request an interactive session for installing packages
srun --time=01:00:00 --mem=16G --pty bash
```

### 3.2 Load R Module
```bash
# Check available R versions
module avail R

# Load R (use the latest version available)
module load R/4.3.1
module load gcc/11.3.0

# Create your personal R library directory
mkdir -p ~/R/libs
export R_LIBS_USER=~/R/libs
```

### 3.3 Install Required Packages
```bash
# Run the setup script
cd ~/R_didgt_polars/cluster
Rscript setup_packages.R
```

### 3.4 Install polars Manually (if needed)

If polars installation fails, try this alternative method:

```r
# Start R
R

# In R console:
options(repos = c(
  rpolars = "https://rpolars.r-universe.dev",
  CRAN = "https://cloud.r-project.org"
))
install.packages("polars")

# Verify it works
library(polars)
pl$DataFrame(a = 1:3)
```

### 3.5 Install Your Polars Package

```r
# In R console (still in interactive session):
library(devtools)

# Install from local directory
install("~/R_didgt_polars", dependencies = FALSE)

# Verify
library(DIDmultiplegtDYNpolars)
```

Exit the interactive session:
```bash
exit
```

## Step 4: Submit the Benchmark Job

```bash
# Navigate to cluster scripts
cd ~/R_didgt_polars/cluster

# Submit the job
sbatch submit_benchmark.sh

# Check job status
squeue -u $USER

# View job output (replace JOBID with actual job ID)
tail -f benchmark_JOBID.out
```

## Step 5: Monitor and Retrieve Results

### Check Job Status
```bash
# See all your jobs
squeue -u $USER

# Detailed job info
scontrol show job JOBID

# See completed jobs
sacct -u $USER --starttime=2024-01-01
```

### View Output
```bash
# View stdout
cat benchmark_JOBID.out

# View stderr (errors)
cat benchmark_JOBID.err

# Real-time monitoring
tail -f benchmark_JOBID.out
```

### Download Results to Local Machine
```bash
# From your local terminal
scp your_netid@crcfe01.crc.nd.edu:~/R_didgt_polars/tests/benchmark_results_complete.csv .
scp your_netid@crcfe01.crc.nd.edu:~/R_didgt_polars/tests/benchmark_wolfers_complete.log .
```

## Troubleshooting

### Problem: polars installation fails
```bash
# Try installing from source with specific options
module load gcc/11.3.0
module load cmake

R -e 'install.packages("polars", repos = "https://rpolars.r-universe.dev", type = "source")'
```

### Problem: Package not found error
```bash
# Make sure R_LIBS_USER is set correctly
export R_LIBS_USER=~/R/libs
echo 'export R_LIBS_USER=~/R/libs' >> ~/.bashrc
```

### Problem: Out of memory error
Edit `submit_benchmark.sh` and increase memory:
```bash
#SBATCH --mem=128G
```

### Problem: Job times out
Edit `submit_benchmark.sh` and increase time:
```bash
#SBATCH --time=08:00:00
```

### Check Available Modules
```bash
module avail R
module avail gcc
module spider polars  # might not exist, that's OK
```

## File Structure on Cluster

After setup, your directory should look like:
```
~/R_didgt_polars/
├── cluster/
│   ├── submit_benchmark.sh      # SLURM job script
│   ├── setup_packages.R         # Package installation script
│   └── README_CRC.md            # This file
├── data/
│   └── wolfers2006_didtextbook.dta
├── tests/
│   ├── benchmark_wolfers_complete.R
│   └── ... (other test files)
├── R/
│   └── ... (package source files)
├── DESCRIPTION
└── NAMESPACE
```

## Quick Start Summary

```bash
# 1. Upload project
scp -r R_didgt_polars your_netid@crcfe01.crc.nd.edu:~/

# 2. SSH to cluster
ssh your_netid@crcfe01.crc.nd.edu

# 3. Install packages (interactive session)
srun --time=01:00:00 --mem=16G --pty bash
module load R/4.3.1 gcc/11.3.0
export R_LIBS_USER=~/R/libs
mkdir -p $R_LIBS_USER
cd ~/R_didgt_polars/cluster
Rscript setup_packages.R
exit

# 4. Submit job
cd ~/R_didgt_polars/cluster
sbatch submit_benchmark.sh

# 5. Monitor
squeue -u $USER
tail -f benchmark_*.out
```

## Contact

For CRC-specific issues, contact: crcsupport@nd.edu
