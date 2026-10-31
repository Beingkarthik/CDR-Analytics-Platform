# Phase 9 - Performance Baseline

Database: CDR_ANALYTICS
Schema: DBT_DEV
Warehouse: COMPUTE_WH

| Metric | Result |
|---|---:|
| Records | 8 |
| Total duration | 1340 seconds |
| Total charge | 161 pence |
| Average duration | 167.5 seconds |

Query tag: PHASE9_OPT1_BASELINE

| Run | Time |
|---|---:|
| 1 | 45 ms |
| 2 | 390 ms |
| 3 | 308 ms |
| 4 | 11 ms |
| 5 | 0 ms rounded |

Median: 45 ms.

Execution times varied considerably on the small eight-row dataset. These measurements provide a reference for query-variant comparisons.
