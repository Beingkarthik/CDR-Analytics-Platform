# Phase 9 - Optimization Experiment Log

## Experiment 1 - Non-negative duration filter
Query tag: PHASE9_OPT1_OPTIMIZED
Times: 13, 10, 303, 2, 1 ms. Median: 10 ms.

## Experiment 2 - Column reduction
Query tag: PHASE9_OPT2_COLUMN_REDUCTION
Times: 11, 312, 302, 266, 292, 275 ms. Six runs. Median: 283.5 ms.

## Experiment 3 - Filtered aggregation
Query tag: PHASE9_OPT3_FILTERED
Times: 9, 10, 314, 307, 660 ms. Median: 307 ms.

The fact table contains only eight records. Both filters retain all eight records. Execution times vary substantially. These are query-variant benchmarks, not proof of sustained performance improvement.
