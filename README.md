# Machine Learning-Based Engine Health Monitoring Using MATLAB

This project investigates whether engine sensor measurements can classify engine operating conditions. It is currently in **Stage 1, dataset verification**. The MATLAB script checks the publisher's training and test data for usable features, labels, and data quality issues before model development begins.

## Problem and objectives

Engine condition is difficult to infer from a single measurement. This project will evaluate whether six measurements of speed, pressure, and temperature can support a supervised classifier. Stage 1 establishes the data schema, checks split integrity, and produces a reproducible inspection report and exploratory plots.

## Tools and requirements

- MATLAB on Windows. Stage 1 uses base MATLAB functions for CSV import, table operations, and graphics.
- Git for version control.
- The two original CSV files in `data/raw/`.

## Dataset

The splits are published by `mukherjee78` in the [Predictive Maintenance Engine Data dataset](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data). The dataset card lists MIT as the license. Download the original [train.csv](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data/resolve/main/train.csv) and [test.csv](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data/resolve/main/test.csv) into `data/raw/`. The files are 1,025,834 and 256,533 bytes, respectively, in the inspected download. Both are kept local so the project uses the publisher's files without redistributing them.

The documented target is `engine_condition`. The publisher's card does not define what the observed numeric codes mean.

## Run Stage 1

In MATLAB, run the script by its full path from any working directory.

```matlab
run('C:/Machine Learning-Based Engine Health Monitoring/run_stage1.m')
```

The script prints its findings and saves `results/reports/dataset_verification.txt`. It writes three PNGs under `results/figures/` when sufficient data are available. The class chart compares the splits. Histograms and Pearson correlations use training inputs only.

## Project structure

```text
data/
  raw/             Original CSVs (local downloads)
  processed/       Reserved for prepared datasets
src/
  preprocessing/   Reserved for data preparation
  models/          Reserved for classifiers
  evaluation/      Reserved for model evaluation
  prediction/      Reserved for inference
dashboard/         Reserved for the MATLAB dashboard
results/
  figures/         Dataset verification charts
  reports/         Dataset verification report
docs/              Project documentation
tests/             Reserved for project tests
.gitignore
README.md
run_stage1.m
```

## Development stages

1. **Current** — Verify the dataset, summarize data quality, and visualize the inputs and labels.
2. **Planned** — Prepare data and validate the labeling and splitting assumptions.
3. **Planned** — Compare KNN, Decision Tree, and SVM classifiers and visualize their performance.
4. **Planned** — Build an interactive MATLAB dashboard for viewing predictions and results.
