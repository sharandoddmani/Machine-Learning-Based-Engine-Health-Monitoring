# User guide

## Set up and open the project

Install MATLAB R2025b Update 3 on Windows with Statistics and Machine Learning
Toolbox. Open the project checkout as MATLAB's Current Folder. For command-line
use, change to that same folder in Windows CMD before starting MATLAB.

The prediction tools need a local `data/processed/final_engine_model.mat`.
If it is missing, obtain the two publisher CSVs as described in the
[reproducibility guide](reproducibility_guide.md) and run `run_stage4` separately
in MATLAB. Dashboard and command-window predictions then use the saved
artifact without needing the CSVs.

## Command-window prediction

Run `run_stage5`. Enter each of the six values when prompted. Re-enter an
invalid value or type `q` to exit. After a successful prediction, answer the
repeat prompt to continue or exit.

Run `run_stage5_demo` for the following illustrative reading:

```matlab
[800, 3.3, 6.6, 2.3, 77.6, 78.4]
```

| Field | Illustrative value |
| --- | ---: |
| `engine_rpm` | 800 |
| `lub_oil_pressure` | 3.3 |
| `fuel_pressure` | 6.6 |
| `coolant_pressure` | 2.3 |
| `lub_oil_temp` | 77.6 |
| `coolant_temp` | 78.4 |

With the approved artifact, the expected result is **Class 1**. The
approximate scores are **0.39908638** for Class 0 and **0.60091362** for Class 1.
The values are illustrative and represent no verified physical engine state.
The classes identify the dataset's numeric labels. The scores are model
outputs in class order and have no established probability calibration.

## Dashboard

1. Run `run_stage6` from MATLAB.
2. Enter the six values in the order shown above. The dashboard labels are
   human-readable, and each field's tooltip gives the exact feature name.
3. Select **Predict**. The predicted class, score chart, and six separate
   raw-value tiles update after successful inference.
4. If a field is rejected, use the status message to find it and correct it.
   Enter a single finite real number, such as `3.3` or `2e-3`. The dashboard
   clears previous output when the new reading is invalid.
5. Select **Reset** to clear the fields, outputs, and messages. Use the window
   close control to exit.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| Final MAT file is missing | Generate it separately with Stage 4 or obtain the approved artifact and place it under `data/processed/`. |
| Bundle is unreadable or incompatible | Check that it is the Stage 4 final artifact and that the Statistics and Machine Learning Toolbox is installed. Recover the approved copy or regenerate it with Stage 4. |
| MATLAB cannot find the entry point | Set the checkout root as the Current Folder. |
| Invalid reading | Check that all six fields contain exactly one finite real number. Remove units, separators, or other text. |
| MATLAB fails at startup in the automated environment | Use normal Windows CMD with the installed MATLAB. Run the verification commands in the reproducibility guide. |
| Invisible UI smoke test fails to initialize figures | Run it in a Windows session that supports native MATLAB figures and check the visible dashboard manually. |
