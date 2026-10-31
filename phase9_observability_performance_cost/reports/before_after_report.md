# Phase 9 - Before and After Performance Report

| Experiment | Runs | Median |
|---|---:|---:|
| Baseline | 5 | 45 ms |
| Non-negative duration filter | 5 | 10 ms |
| Column reduction | 6 | 283.5 ms |
| Filtered aggregation | 5 | 307 ms |

The first query variant showed a lower observed median, but execution times varied considerably. The dataset contains only eight records, and the filters retain all eight. Column reduction is a different workload because it calculates fewer aggregates. These results do not establish a controlled performance improvement or prove that the 30 percent target was achieved. Further testing on a larger dataset is required.
