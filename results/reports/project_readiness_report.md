# Machine Learning-Based Engine Health Monitoring Using MATLAB

## Scope and implementation

This academic benchmark evaluates whether six engine sensor features can
predict the publisher's numeric condition labels. The implementation covers
dataset verification, preprocessing and EDA, model training and validation,
held-out evaluation, manual prediction, a native MATLAB dashboard, and final
integration and documentation. The dashboard accepts manual input only.

## Dataset and model selection

The [publisher dataset](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data)
provides 15,628 training and 3,907 test rows with six predictors and an
`engine_condition` target. A seed-42 stratified split of publisher training
provided 12,502 development-training and 3,126 validation rows. The tested
algorithms were KNN, Decision Tree, and SVM. Validation selected a Decision
Tree (`MaxNumSplits = 30`, `SplitCriterion = 'gdi'`, `MinLeafSize = 1`, and
empirical priors) using macro F1, balanced accuracy, accuracy, and fixed
candidate order. The model and preprocessing were refitted on all publisher
training rows before scoring the held-out test set.
[Stage 3 validation report](model_training_report.txt)

## Performance

| Metric | Stage 3 validation tree | Stage 4 held-out tree | Held-out majority baseline |
| --- | ---: | ---: | ---: |
| Accuracy | 0.664427 | 0.659841 | 0.630407 |
| Macro F1 | 0.616311 | 0.596498 | 0.386656 |
| Balanced accuracy | 0.613813 | 0.597122 | 0.500000 |
| Class 0 recall | 0.419913 | 0.356648 | 0.000000 |
| Class 1 recall | 0.807712 | 0.837596 | 1.000000 |

| Held-out tree | Precision | Recall | F1 |
| --- | ---: | ---: | ---: |
| Class 0 | 0.562842 | 0.356648 | 0.436626 |
| Class 1 | 0.689505 | 0.837596 | 0.756370 |

| Actual row / predicted column | Class 0 | Class 1 |
| --- | ---: | ---: |
| Class 0 | 515 | 929 |
| Class 1 | 400 | 2,063 |

The held-out tree correctly classified 2,578 rows and misclassified 1,329.
The baseline predicts the training majority label, Class 1, for every row.
The tree improves held-out accuracy by 2.943 percentage points, macro F1 by
20.984 points, balanced accuracy by 9.712 points, and Class 0 recall by 35.665
points. Class 0 recall remains low. Validation and held-out results compare
different fitted trees and partitions, so their differences cannot isolate
overfitting. [Stage 4 held-out evaluation report](final_model_evaluation.txt)

## Demonstration and reproducibility

The approved Stage 6 verification used `[800, 3.3, 6.6, 2.3, 77.6, 78.4]`.
The smoke test reported Class 1 with scores approximately
`[0.39908638, 0.60091362]`, ordered by Class 0 and Class 1. The reading is
illustrative. The dashboard uses the same inference API as the command-window
demo, supports correction and Reset, and displays the raw values separately.

Reproduction requires MATLAB R2025b Update 3, Statistics and Machine
Learning Toolbox, and the publisher CSVs. Saved-model inference requires the
local final MAT file and project source. The dashboard additionally requires a
session supporting MATLAB UI figures. The artifact is intentionally excluded
from Git. [Reproducibility guide](../../docs/reproducibility_guide.md)

## Verification and submission status

| Check | Status |
| --- | --- |
| Approved Stage 6 full suite | 27 passed, 0 failed, as reported for the approved checkpoint |
| Approved Stage 6 dashboard smoke test | PASS, as reported for the approved checkpoint |
| Stage 7 integration runner and full suite | Pending local MATLAB execution; Codex MATLAB failed at startup |
| Independent Stage 7 full-suite run | Pending local MATLAB execution; Codex MATLAB failed at startup |
| Visible dashboard walkthrough for submission | Pending local verification |
| GitHub checkpoint | Prior approved revision `94222a0da1238706104b6305bcf433ac3ea688dc`; Stage 7 awaits verification and project-guide approval |

For submission, run the Stage 7 commands in normal Windows CMD, retain the
actual output, and walk through Predict, invalid input, Reset, and Close in the
visible dashboard. After project-guide approval, review and publish only
Stage 7 source, tests, documentation, and this report.

The physical class meanings, acquisition process, pressure and temperature
units, and publisher split method remain unverified. There are no engine IDs
or timestamps. The scores are uncalibrated. The benchmark establishes no
real-world reliability and provides no fault diagnosis, remaining life
estimation, or live hardware integration.
[Model limitations](../../docs/model_limitations.md)
