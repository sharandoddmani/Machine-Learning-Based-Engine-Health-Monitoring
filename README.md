# Machine Learning-Based Engine Health Monitoring Using MATLAB

This project investigates whether engine sensor measurements can classify engine operating conditions. **Stage 2 preprocessing and exploratory analysis are complete.** Stage 1 and Stage 2 ran successfully in MATLAB R2025b Update 3 on Windows, and all seven preprocessing tests passed.

## Problem and objectives

Engine condition is difficult to infer from a single measurement. This project will evaluate whether six measurements of speed, pressure, and temperature can support a supervised classifier. Stage 1 establishes the data schema, checks split integrity, and produces a reproducible inspection report and exploratory plots.

## Tools and requirements

- MATLAB R2025b on Windows. Stages 1 and 2 use base MATLAB for data preparation and graphics.
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

## Run Stage 2

From the project directory in MATLAB:

```matlab
run_stage2
results = runtests('tests');
assertSuccess(results);
```

The loader validates the six numeric sensors and the binary `engine_condition`
target. It extracts sensors in the order defined by `engineSchema`. Missing or
nonfinite readings cause an error.

The development split reserves the nearest integer to 20% from each class using
a local MT19937 stream with seed 42. This specifies 12,502 development-training
and 3,126 validation records. For validation, the pipeline fits the feature means
and sample standard deviations on development-training only and applies those
parameters to validation. A zero sample standard deviation uses a divisor of one.
Future readings use `applyEnginePreprocessing(reading, parameters)` with six
ordered values per row.

For the final benchmark, after model choices are fixed and approved, refit
`fitEnginePreprocessing` on all 15,628 rows of `train.csv` and use that fit to
transform `test.csv` for final evaluation. Stage 2 checks that the test sensors
transform to finite values and excludes test records from the saved MAT file,
the split decisions, the fit, and the exploratory analysis.

Stage 2 writes `stage2_sensor_histograms.png`, `stage2_sensor_boxplots.png`,
`stage2_sensor_correlation.png`, and `stage2_class_distribution.png` under
`results/figures/`. It also writes the preprocessing and feature-analysis text
reports under `results/reports/` and a local `data/processed/stage2_preprocessing.mat`
with development and validation matrices, labels, source row indices, and fitted
parameters. The original CSVs reconstruct all generated outputs. The reports contain the
MATLAB results, including the fitted development-training statistics.

The publisher provides no confirmed code-to-condition mapping, acquisition or
simulation protocol, or publisher split procedure. Speed is identified as RPM
by the header. Pressure and temperature units are unverified. Engine IDs and
timestamps are absent from the two CSVs, so engine-level and temporal independence
cannot be verified. Figures use Class 0 and Class 1. See
[dataset provenance](docs/dataset_provenance.txt) for evidence.

## Project structure

```text
data/
  raw/             Original CSVs (local downloads)
  processed/       Local Stage 2 MAT file
src/
  preprocessing/   Schema, splitting, standardization, and EDA
  models/          Reserved for classifiers
  evaluation/      Reserved for model evaluation
  prediction/      Reserved for inference
dashboard/         Reserved for the MATLAB dashboard
results/
  figures/         Stage 1 and Stage 2 figures
  reports/         Dataset and feature reports
docs/              Project documentation
tests/             MATLAB preprocessing tests
.gitignore
README.md
run_stage1.m
run_stage2.m
```

## Development stages

1. **Complete** — Verify the dataset, summarize data quality, and visualize the inputs and labels.
2. **Complete** — Prepare data, explore the training split, and document provenance.
3. **Pending project-guide approval** — Compare KNN, Decision Tree, and SVM classifiers and visualize their performance.
4. **Planned** — Build an interactive MATLAB dashboard for viewing predictions and results.
