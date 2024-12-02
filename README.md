Here’s the revised **README** with the note at the top:

---

# README

## **Note: This repository is currently under development.**  
**Do not use this code in its current state. Features and functionality are incomplete and subject to change.**

---

## Change Point Detection and Drift Diffusion Model Fitting

This repository contains MATLAB and Python scripts for fitting and simulating Drift Diffusion Models (DDMs) for behavioral data from the Change Point Detection (CPD) Task. It supports subject-level modeling and Slurm batch processing for scalability.

---

### Repository Files

#### MATLAB Scripts
1. **`main_DDM.m`**  
   - Main script for fitting and simulating DDMs.
   - Reads behavioral data, configures priors, fits the model using `fit_CPD`, and runs simulations with fitted parameters via `simfit_CPD`.
   - Outputs results as `.csv` files.

2. **`fit_CPD.m`**  
   - Handles CPD model fitting.
   - Reads and processes subject behavioral data, computes likelihoods, and stores model results.
   - Invokes the `inversion_CPD` function for model optimization.

3. **`inversion_CPD.m`**  
   - Core model fitting script.
   - Performs variational Bayesian inversion to optimize model parameters.
   - Outputs posterior parameter estimates and model evidence (free energy).

4. **`simfit_CPD.m`**  
   - Simulates behavior based on fitted model parameters.
   - Refits the model on simulated data to assess the reliability of parameter estimates.

---

#### Python Scripts
1. **`CPD_fitting.py`**  
   - Automates CPD model fitting for multiple subjects and configurations.
   - Submits Slurm jobs using `CPD_bash.ssub`, dynamically creating directories for results and logs.

---

#### Slurm Batch Script
1. **`CPD_bash.ssub`**  
   - Template for Slurm-based job submission.
   - Executes model fitting for individual subjects and configurations.

---

### Usage
1. **MATLAB Workflow:**
   - Edit `main_DDM.m` to configure paths and parameters.
   - Run the script to process data, fit models, and save results.

2. **Batch Processing:**
   - Modify `CPD_fitting.py` with your subject list and result directory.
   - Execute: `python3 CPD_fitting.py <result_directory>`.

3. **Slurm Integration:**
   - Ensure `CPD_bash.ssub` points to the correct MATLAB environment.

---

### Dependencies
- MATLAB with `spm12` and related toolboxes.
- Python 3.8+ with OS and subprocess libraries.
- Slurm for HPC job scheduling.

### Contributors
- **Carter Goldman**: Developer and maintainer.

--- 

Let me know if you need further updates!
