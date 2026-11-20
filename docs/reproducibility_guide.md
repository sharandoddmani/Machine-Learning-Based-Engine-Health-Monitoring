# Reproducibility guide

## Requirements and input files

Use MATLAB R2025b Update 3 on Windows with Statistics and Machine Learning
Toolbox. Stages 1 and 2 use base MATLAB. The dashboard and its smoke tests
require a session that supports native MATLAB UI figures, including invisible
figures. Use Git to obtain the source and keep a record of the checked-out
revision with `git rev-parse HEAD`.

Download the publisher's original files from the
[mukherjee78 dataset card](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data).
Place [train.csv](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data/resolve/main/train.csv)
in `data/raw/train.csv` and
[test.csv](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data/resolve/main/test.csv)
in `data/raw/test.csv`. Expect 15,628 training and 3,907 test rows, with seven
columns in each file. The six predictors in model order are:

1. `engine_rpm`
2. `lub_oil_pressure`
3. `fuel_pressure`
4. `coolant_pressure`
5. `lub_oil_temp`
6. `coolant_temp`

The target is `engine_condition`, encoded as numeric 0 and 1. The publisher
supplies the outer train/test split. Its construction and engines' identities
are unverified.

## Fresh reproduction

In normal Windows CMD, set the current directory to your checkout. Replace
`<project-root>` with its local path.

```cmd
cd /d "<project-root>"
matlab -wait -batch "run_stage1; run_stage2; run_stage3; run_stage4"
```

1. Stage 1 verifies the source schema, sizes, labels, and overlap and produces
   the dataset report and figures.
2. Stage 2 uses a seed-42 MT19937 stream to hold out approximately 20% within
   each class from publisher training. It produces 12,502 development-training
   rows (4,619 Class 0, 7,883 Class 1) and 3,126 validation rows (1,155 Class 0,
   1,971 Class 1). Development rows alone determine the means and sample standard
   deviations used to standardize both partitions.
3. Stage 3 recreates the same split from `train.csv`. It compares KNN, Decision Tree,
   and SVM by validation macro F1, balanced accuracy, accuracy, and then fixed
   candidate order. It selects the Decision Tree with a maximum of 30 splits.
4. Stage 4 refits the locked tree and standardization on all 15,628 training rows.
   It scores the held-out test set after fitting and confirms that reloading the
   saved bundle preserves all 3,907 test predictions.

The local `data/processed/stage2_preprocessing.mat` and
`data/processed/stage3_models.mat` record development work.
`data/processed/final_engine_model.mat` is the artifact required by Stages 5–7.
Stage 4 can regenerate it directly from the two CSVs using `run_stage4`.
Reproduction can change the recorded training timestamp and rendered
figure bytes. Preserve an existing approved artifact when the goal is to
verify or demonstrate the published model.

The repository tracks source and text reports, plus the approved Stage 1
figures. Raw CSVs, generated model MAT files, and regenerable Stage 2–4
figures are excluded by Git. A GitHub checkout contains the code and reports.
The trained model must be generated locally or supplied separately.

## Normal demonstration

With the final MAT file in place, no earlier stage or CSV is needed. From
the project directory in MATLAB:

```matlab
run_stage5       % Command-window prompts
run_stage5_demo  % Noninteractive illustrative reading
run_stage6       % Interactive dashboard
```

## Verification

Use normal Windows CMD from the project directory:

```cmd
matlab -wait -batch "run_stage7;"
matlab -wait -batch "results = runtests('tests'); disp(results); assertSuccess(results)"
```

Stage 7 runs the saved-model demo and invisible dashboard smoke test, then the
full test suite. The full suite also needs the raw CSVs because earlier-stage
regression tests exercise training and evaluation using temporary or in-memory
results. The approved artifact and tracked Stage 4 evaluation are read-only
during verification. For a check with only the final artifact, use
`matlab -wait -batch "run_stage5_demo; run_stage6_smoke"`.

See the [user guide](user_guide.md) for an on-screen walkthrough and the
[readiness report](../results/reports/project_readiness_report.md) for the
verification status.
