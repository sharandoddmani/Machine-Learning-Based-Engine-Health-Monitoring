# Machine Learning-Based Engine Health Monitoring Using MATLAB

This academic project compares supervised classifiers on six engine sensor
features. It includes dataset verification, preprocessing and EDA, candidate
training, held-out evaluation, command-window prediction, and a native MATLAB
dashboard. The approved Decision Tree has a 30-split cap and achieved held-out
accuracy **0.659841**, macro F1 **0.596498**, and balanced accuracy **0.597122**.
The dashboard displays numeric classes and uncalibrated scores. Physical class
meanings and real-world reliability remain unverified.

## Quick start

Use MATLAB R2025b Update 3 on Windows with Statistics and Machine Learning
Toolbox. Open the checkout as MATLAB's Current Folder. With the approved
`data/processed/final_engine_model.mat` in place:

```matlab
run_stage5_demo
run_stage6
```

For a fresh reproduction, download the two publisher CSVs described below
and run these commands from normal Windows CMD. Substitute the local checkout
path for `<project-root>`.

```cmd
cd /d "<project-root>"
matlab -wait -batch "run_stage1; run_stage2; run_stage3; run_stage4"
```

To regenerate only the final artifact, run `run_stage4` with both CSVs in
place. Git tracks source and reports. The original CSVs, generated MAT files,
and regenerable Stage 2?4 figures stay local. Preserve an existing approved
MAT file for routine demonstration and verification.

## Documentation

- [Reproducibility guide](docs/reproducibility_guide.md)
- [System architecture](docs/system_architecture.md)
- [User guide](docs/user_guide.md)
- [Model limitations](docs/model_limitations.md)
- [Project readiness report](results/reports/project_readiness_report.md)

## Problem and objectives

Engine condition is difficult to infer from a single measurement. This project will evaluate whether six measurements of speed, pressure, and temperature can support a supervised classifier. Stage 1 establishes the data schema, checks split integrity, and produces a reproducible inspection report and exploratory plots.

## Tools and requirements

- MATLAB R2025b Update 3 on Windows. Stages 1 and 2 use base MATLAB for data preparation and graphics. Stages 3?6 need Statistics and Machine Learning Toolbox.
- Git for version control.
- The original CSVs in `data/raw/` for reproduction and full regression testing. The prediction tools use only the saved final artifact and source files.

## Dataset

The splits are published by `mukherjee78` in the [Predictive Maintenance Engine Data dataset](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data). The dataset card lists MIT as the license. Download the original [train.csv](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data/resolve/main/train.csv) and [test.csv](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data/resolve/main/test.csv) into `data/raw/`. The files are 1,025,834 and 256,533 bytes, respectively, in the inspected download. Both are kept local so the project uses the publisher's files without redistributing them.

The documented target is `engine_condition`. The publisher's card does not define what the observed numeric codes mean.

## Run Stage 1

From the project directory in MATLAB:

```matlab
run_stage1
```

The script prints its findings and saves `results/reports/dataset_verification.txt`. It writes three PNGs under `results/figures/` when sufficient data are available. The class chart compares the splits. Histograms and Pearson correlations use training inputs only.

## Run Stage 2

From the project directory in MATLAB:

```matlab
run_stage2
results = [runtests('tests/testEnginePreprocessing.m'), ...
    runtests('tests/testEnginePreprocessingUnits.m')];
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

## Run Stage 3

Stage 3 requires Statistics and Machine Learning Toolbox. From the project
directory in MATLAB:

```matlab
run_stage3
results = runtests('tests');
assertSuccess(results);
```

The benchmark reproduces the Stage 2 stratified split (seed 42) from
`train.csv`. It fits on 12,502 development rows and compares candidates on the
same 3,126 validation rows. All models use the same six features and
development-only standardization. Stage 3 reads only `train.csv`. Final
evaluation on the publisher test split is a separate stage.

| Algorithm | Candidate settings |
| --- | --- |
| KNN | 3, 5, 7, or 11 neighbors. Euclidean distance, equal weights, k-d tree search, class ties resolved toward the smaller code. |
| Decision Tree | Maximum splits of 10, 30, or 100. Gini impurity and minimum leaf size of one. |
| SVM | Linear and Gaussian (RBF) kernels. Box constraint 1, kernel scale 1, SMO solver. |

All fits use empirical class priors. KNN and SVM disable internal standardization.
Each algorithm's best configuration and the overall candidate are ranked by
unrounded macro F1, balanced accuracy, then accuracy. An exact tie goes to the
first listed candidate in the table order. Undefined class precision, recall,
and F1 are set to zero. Confusion matrices use actual rows and predicted columns,
both ordered Class 0 then Class 1.

The run writes `results/reports/model_training_report.txt` with every candidate's
metrics and setting. It generates `stage3_algorithm_comparison.png`,
`stage3_confusion_matrices.png`, and `stage3_class_performance.png` under
`results/figures/`. The local `data/processed/stage3_models.mat` stores all fitted
candidates, metadata, validation results, and the preprocessing fit. The
artifact and figures are regenerated locally.

Validation results guided the approved model and hyperparameter choice.

## Run Stage 4

Stage 4 uses Statistics and Machine Learning Toolbox. From the project
directory in MATLAB:

```matlab
run_stage4
results = runtests('tests');
assertSuccess(results);
```

Stage 3 selected a Decision Tree with `MaxNumSplits = 30`, `SplitCriterion =
'gdi'`, `MinLeafSize = 1`, and empirical priors. Its development-trained
validation accuracy was 0.664427, macro F1 was 0.616311, and balanced accuracy
was 0.613813. Class 0 recall was 0.419913 and Class 1 recall was 0.807712.

Stage 4 refits standardization and the locked tree on all 15,628 publisher
training rows. It then scores the 3,907 held-out test rows. The test split
contributes no fitted statistics or model choices. Stage 3 validation and
Stage 4 test evaluate different model fits and partitions.

The majority baseline predicts Class 1, the majority class in `train.csv`.
From the publisher test counts, its accuracy is 0.630407, macro F1 is 0.386656,
balanced accuracy is 0.500000, and Class 0 recall is zero. The final tree's
held-out accuracy was 0.659841, macro F1 was 0.596498, and balanced accuracy
was 0.597122. The confusion matrix was `[515 929; 400 2063]` in [0, 1] order.

Stage 4 writes `results/reports/final_model_evaluation.txt` and four PNGs
under `results/figures/`. They cover the held-out confusion matrix, class
metrics, validation versus test, and tree versus baseline. The local artifact
`data/processed/final_engine_model.mat` stores a `bundle` with the compact
tree (`bundle.model`), full-training standardization (`bundle.preprocessing`),
predictor order, class labels, locked settings, fit metadata, and final test
metrics. The run checks that the reloaded bundle produces identical predictions.

The test measures an academic benchmark on the publisher's data. Class meanings,
engine-level and chronological independence, and acquisition conditions remain
unverified.

## Run Stage 5

Manual inference requires MATLAB R2025b, Statistics and Machine Learning Toolbox,
the project source, and the local Stage 4 artifact
`data/processed/final_engine_model.mat`. Git excludes the MAT file. If it is
missing, run Stage 4 separately to generate it. Stage 5 uses the saved model and
preprocessing without opening either CSV or fitting anything.

From the project directory, run `run_stage5` to enter the sensors one by one.
Invalid entries can be retried. Type `q` at a sensor prompt to exit, or answer
the repeat prompt after a prediction. Run `run_stage5_demo` to print an
illustrative reading, its predicted class, and the model scores without prompts.
The example represents no verified engine condition.

Numeric input uses this order:

1. `engine_rpm`
2. `lub_oil_pressure`
3. `fuel_pressure`
4. `coolant_pressure`
5. `lub_oil_temp`
6. `coolant_temp`

The same functions can be called from a script or the dashboard:

```matlab
addpath(fullfile('src','inference'), fullfile('src','preprocessing'));
bundle = loadFinalEngineModel(fullfile('data','processed','final_engine_model.mat'));
reading = [800, 3.3, 6.6, 2.3, 77.6, 78.4];
result = predictEngineCondition(bundle, reading);
```

The prediction function accepts a numeric `1-by-6` row, a scalar sensor struct,
or a single-row sensor table. Named inputs can list the six sensors in any order.
Every value must be a real, finite numeric scalar. Missing and extra names,
text and cell values, and multiple readings are rejected. MATLAB table variable
names are unique by construction. Readings are neither clamped nor screened
against presumed physical limits.

The result contains `predictedClass`, `featureNames`, `rawReadings`,
`standardizedReadings`, `classLabels`, and `scores`. Score columns follow
`classLabels` (Class 0 then Class 1). It also records `algorithm`,
`hyperparameters`, `trainingRows`, `matlabVersion`, and `trainingTimestampUtc`.
Scores are uncalibrated model outputs. The publisher's labels have unverified
physical meanings, so the result uses Class 0 and Class 1.

The inference functions have no command-window or graphics dependencies.

## Run Stage 6

Open MATLAB R2025b Update 3 on Windows with Statistics and Machine Learning
Toolbox and the local `data/processed/final_engine_model.mat` artifact. From
the project directory:

```matlab
run_stage6
```

Enter the six readings in order (`engine_rpm`, `lub_oil_pressure`,
`fuel_pressure`, `coolant_pressure`, `lub_oil_temp`, `coolant_temp`) and
select **Predict**. The dashboard shows the saved Decision Tree's predicted
class and uncalibrated classification scores. Each sensor has a separate
raw-value tile because the magnitudes have different scales and several units
are unverified. Class 0 and Class 1 have unverified physical meanings.

Inputs accept decimal and scientific notation. A validation error identifies the
field and clears any previous prediction and charts. **Reset** also clears
the inputs and restores the initial status. The dashboard loads the model once
on launch and uses the Stage 5 inference API for each prediction. No raw data
files are needed to run the dashboard. If MATLAB reports a missing or invalid
model, run Stage 4 separately to generate the artifact.

Run the smoke test and full suite in a MATLAB session that supports native UI
figures:

```matlab
run_stage6_smoke
results = runtests('tests');
disp(results);
assertSuccess(results);
```

For programmatic verification, `app = run_stage6("off")` returns the figure,
six input handles, output handles, and `app.Predict()`, `app.Reset()`, and
`app.Close()` callbacks. Set `app.Inputs(k).Value` to a numeric text value.
The smoke test exercises the same callbacks as the visible controls.

This is an academic demonstration for manually entered readings. It has no
live sensor feed, physical fault interpretation, or calibrated probabilities.

## Run Stage 7 verification

With the saved final artifact and both raw CSVs present, run from normal
Windows CMD in the checkout root:

```cmd
matlab -wait -batch "run_stage7;"
matlab -wait -batch "results = runtests('tests'); disp(results); assertSuccess(results)"
```

The runner verifies the saved model through the Stage 5 demo, runs the Stage 6
dashboard smoke test, and runs the full suite. Earlier-stage regression tests
exercise training and scoring without replacing the approved artifact or
publishing a fresh held-out evaluation. Stage 7 verification is pending.

## Project structure

```text
data/
  raw/             Original CSVs (local downloads)
  processed/       Local prepared data and model artifacts
src/
  preprocessing/   Schema, splitting, standardization, and EDA
  models/          KNN, Decision Tree, and SVM
  evaluation/      Validation and held-out evaluation
  inference/       Saved-model loading and single-reading prediction
  dashboard/       Native MATLAB dashboard and callbacks
results/
  figures/         Stage 1 through Stage 4 figures
  reports/         Dataset, training, and evaluation reports
docs/              Project documentation
tests/             MATLAB preprocessing, model, and dashboard tests
.gitignore
README.md
run_stage1.m
run_stage2.m
run_stage3.m
run_stage4.m
run_stage5.m
run_stage5_demo.m
run_stage6.m
run_stage6_smoke.m
run_stage7.m
```

## Development stages

1. **Complete** — Verify the dataset, summarize data quality, and visualize the inputs and labels.
2. **Complete** — Prepare data, explore the training split, and document provenance.
3. **Complete** — Compare classifiers on the frozen validation split and select the Decision Tree.
4. **Complete** — Refit the locked tree and evaluate it on the publisher test split.
5. **Complete** — Predict from manually entered sensor readings.
6. **Implemented, execution pending** — Run the interactive dashboard with the saved model.
