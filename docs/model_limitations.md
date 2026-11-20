# Model limitations

This system is an academic supervised classification benchmark based on the
[mukherjee78 predictive maintenance dataset](https://huggingface.co/datasets/mukherjee78/predictive-maintenance-engine-data).
The publisher supplies the train/test partition. Its construction, acquisition
conditions, and the source of the numeric labels remain unverified.
`engine_rpm` identifies speed in RPM. Pressure and temperature units remain
unverified. The CSVs contain no engine identifiers or timestamps, so the
benchmark does not establish engine-group or chronological independence.
See the [dataset provenance notes](dataset_provenance.txt).

## Held-out results

| Metric | Final Decision Tree |
| --- | ---: |
| Accuracy | 65.98% |
| Macro F1 | 59.65% |
| Balanced accuracy | 59.71% |
| Class 0 recall | 35.66% |
| Class 1 recall | 83.76% |

The tree correctly classified 515 of 1,444 Class 0 rows and 2,063 of 2,463
Class 1 rows. The recall difference limits what overall accuracy says about
performance for both classes. See the [Stage 4 evaluation](../results/reports/final_model_evaluation.txt).

Class 0 and Class 1 have unverified physical meanings. The displayed scores
are uncalibrated. The project has no real-world reliability validation,
real-time hardware connection, physical fault diagnosis, or remaining useful
life estimation. The manual interface demonstrates inference on one ordered
reading at a time.
