Required live evidence to capture after running dbt in your Snowflake account:
1. dbt docs lineage graph screenshot (all three mart models visible).
2. dbt build/dbt test terminal screenshot with zero failures/errors.
3. Snapshot proof for one changed subscriber showing dbt_valid_to on old version and current new version.
4. Contract failure screenshot after deliberate breaking schema change, followed by successful restored build.
5. Phase 5 EXCEPT checks in both directions for every Gold table, showing zero rows.
These are intentionally not fabricated in this package. The lineage_graph.png in the report is a model-design diagram, not a screenshot of a live dbt docs run.
