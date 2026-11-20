# System architecture

```text
Publisher CSVs
    |
    +--> Stage 1: dataset verification
    |
    +--> Stage 2: preprocessing and EDA
    |       Publisher training -> development-training + validation
    |                                   |
    |                                   v
    |       Stage 3: train candidates / select on validation
    |                                   |
    |                                   v
    |                           Locked Decision Tree
    |                                   |
    +--> All publisher training -> Stage 4: refit transform and tree
    |                                   |
    +--> Publisher test ----------> Held-out scoring
                                        |
                                        v
                                  Final MAT bundle
                                     /        \
                                    v          v
                             Stage 5 CLI   Stage 6 dashboard
```

## Predictor contract

The canonical order from `engineSchema` is `engine_rpm`, `lub_oil_pressure`,
`fuel_pressure`, `coolant_pressure`, `lub_oil_temp`, and `coolant_temp`.
`engine_condition` supplies labels and is excluded from predictors.

During development, standardization is fitted on development-training rows and
applied to validation rows. The final refit uses the means and sample standard
deviations of all publisher training rows. A zero standard deviation uses a
scale of 1. The held-out test rows use those fixed final parameters. Publisher
test metrics are excluded from model selection.

## Saved bundle and inference

`data/processed/final_engine_model.mat` stores a `bundle` with the compact tree,
ordered feature names, class labels, fitted preprocessing, hyperparameters,
training metadata, and final test metrics. `loadFinalEngineModel` validates
the bundle. `predictEngineCondition` validates and orders a single reading,
applies `applyEnginePreprocessing` with the saved parameters, then calls
MATLAB `predict`. It returns the original and standardized values, the class,
and the scores in the model's class order, plus relevant model metadata.
Class scores are uncalibrated.

The Stage 5 command-window flow prompts for finite numeric inputs or runs an
illustrative reading without prompts. The Stage 6 dashboard loads the bundle
once. Its Predict callback parses one value from each field and calls the same
API. It displays raw values separately, the predicted class, and the scores.
Invalid input clears prior output and identifies the field. Reset clears the
inputs and display. The Stage 6 smoke test exercises these callbacks with an
invisible window.

Stages 5 and 6 use only the inference code, transform helpers, and local
model. Stage 7 verifies those paths and runs legacy and integration tests.
The system accepts manual readings and has no live acquisition path.
