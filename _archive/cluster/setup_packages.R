# =============================================================================
# Setup R Packages for DID Benchmark on CRC Cluster
# =============================================================================
# Run this script ONCE to install all required packages
# Usage: Rscript setup_packages.R

cat("===========================================\n")
cat("Setting up R packages for DID Benchmark\n")
cat("===========================================\n\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Create user library if it doesn't exist
user_lib <- Sys.getenv("R_LIBS_USER")
if (user_lib == "") {
  user_lib <- file.path(Sys.getenv("HOME"), "R/libs")
}
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))

cat("Installing to:", user_lib, "\n\n")

# Function to install package if not already installed
install_if_missing <- function(pkg, ...) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, lib = user_lib, ...)
    cat(pkg, "installed successfully\n\n")
  } else {
    cat(pkg, "already installed\n")
  }
}

# =============================================================================
# 1. Install CRAN dependencies
# =============================================================================
cat("\n--- Installing CRAN packages ---\n\n")

cran_packages <- c(
  "haven",        # For reading .dta files
  "dplyr",        # Data manipulation
  "writexl",      # Excel output
  "data.table",   # Required by DIDmultiplegtDYN
  "devtools",     # For installing from GitHub
  "remotes"       # For installing from GitHub
)

for (pkg in cran_packages) {
  install_if_missing(pkg)
}

# =============================================================================
# 2. Install polars
# =============================================================================
cat("\n--- Installing polars ---\n\n")

if (!requireNamespace("polars", quietly = TRUE)) {
  cat("Installing polars from r-universe...\n")
  # polars is available from r-universe (pre-compiled binaries)
  install.packages(
    "polars",
    repos = "https://rpolars.r-universe.dev",
    lib = user_lib
  )
  cat("polars installed successfully\n")
} else {
  cat("polars already installed\n")
}

# Verify polars works
cat("\nVerifying polars installation...\n")
library(polars)
cat("polars version:", as.character(packageVersion("polars")), "\n")

# =============================================================================
# 3. Install DIDmultiplegtDYN from CRAN
# =============================================================================
cat("\n--- Installing DIDmultiplegtDYN (CRAN) ---\n\n")

install_if_missing("DIDmultiplegtDYN")

# =============================================================================
# 4. Install DIDmultiplegtDYNpolars from GitHub
# =============================================================================
cat("\n--- Installing DIDmultiplegtDYNpolars ---\n\n")

# Option A: Install from local source (if you uploaded the package)
local_pkg_path <- file.path(Sys.getenv("HOME"), "R_didgt_polars")
if (dir.exists(local_pkg_path)) {
  cat("Installing from local source:", local_pkg_path, "\n")
  devtools::install(local_pkg_path, dependencies = FALSE, upgrade = "never")
} else {
  # Option B: Install from GitHub
  cat("Installing from GitHub...\n")
  cat("Note: Replace 'YOUR_GITHUB_USERNAME' with your actual GitHub username\n")
  # remotes::install_github("YOUR_GITHUB_USERNAME/DIDmultiplegtDYNpolars")
  stop("Please upload your package to the cluster or install from GitHub")
}

# =============================================================================
# 5. Verify all packages
# =============================================================================
cat("\n--- Verifying installations ---\n\n")

required_packages <- c(
  "haven",
  "dplyr",
  "writexl",
  "data.table",
  "polars",
  "DIDmultiplegtDYN",
  "DIDmultiplegtDYNpolars"
)

all_ok <- TRUE
for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    ver <- as.character(packageVersion(pkg))
    cat(sprintf("  %-25s v%s  [OK]\n", pkg, ver))
  } else {
    cat(sprintf("  %-25s [MISSING]\n", pkg))
    all_ok <- FALSE
  }
}

if (all_ok) {
  cat("\n===========================================\n")
  cat("All packages installed successfully!\n")
  cat("You can now run the benchmark.\n")
  cat("===========================================\n")
} else {
  cat("\n===========================================\n")
  cat("WARNING: Some packages are missing.\n")
  cat("Please install them manually.\n")
  cat("===========================================\n")
}
