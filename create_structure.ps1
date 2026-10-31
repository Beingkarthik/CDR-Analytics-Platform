$folders = @(
"data/raw","data/cleansed","data/quarantine","logs",
"phase2_data_modeling",
"phase3_data_ingestion/pipeline","phase3_data_ingestion/tests",
"phase4_transformation/scripts",
"phase5_data_warehouse/ddl_scripts","phase5_data_warehouse/etl_scripts","phase5_data_warehouse/validation",
"phase6_airflow/dags","phase6_airflow/scripts","phase6_airflow/config",
"tests","docs/architecture","docs/er_diagram","docs/reports"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
}

Write-Host "CDR Analytics Platform folder structure created."
