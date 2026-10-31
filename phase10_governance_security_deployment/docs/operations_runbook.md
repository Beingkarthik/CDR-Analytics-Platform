# Operations Runbook – CDR Analytics Platform

## 1. Purpose
This runbook records the operational checks for the Phase 10 governance and security work.

## 2. Prerequisites
- Access to the CDR_ANALYTICS Snowflake account.
- An authorized Snowflake role for the requested operation.
- Access to the project repository.
- Local Python and dbt environment for development validation.

Never store passwords, private keys or tokens in the repository or paste them into shared logs.

## 3. Inspect the Snowflake Environment
Open `sql/phase10_security_inspection.sql` in Snowflake Workspace and execute it with an authorized administrative role. Review the active session, schemas, roles, tables and column metadata.

## 4. Role Administration
Review `sql/role_hierarchy.sql` before running it. Role creation and grants require appropriate privileges. Confirm grants with Snowflake `SHOW GRANTS` commands and ensure users receive only the roles required for their duties.

## 5. PII Secure-View Validation
The tested demonstration uses `CDR_ANALYTICS.SECURITY_DEMO.CUSTOMER_PII_TEST` and `V_CUSTOMER_PII_MASKED`.

1. Confirm that the secure view exists and is marked secure.
2. Query the view using `CDR_ANALYST_ROLE` and verify phone/email masking.
3. Query the view using `CDR_SECURITY_ADMIN_ROLE` and verify authorized unmasked output.
4. Record screenshots or query results in `evidence/` after removing any real personal data.

The Snowflake account rejected native masking-policy creation as an unsupported feature. The secure-view approach is the implemented fallback. The demo data is synthetic and must not be replaced with real customer data without an approved privacy and access review.

## 6. dbt Development Validation
From the repository root:

```cmd
cd phase8_realtime_ingestion\dbt_project
.venv\Scripts\activate
dbt parse --no-partial-parse
dbt build --target dev
```

The parse command has been confirmed successful. A development build previously completed with 7 passing results and no errors after the fraud-label assets were temporarily disabled.

The fraud-label model, snapshot and two tests are disabled pending the missing `fraud_labels.csv` source. Do not report fraud-label processing as complete until the source data and model are restored and tested.

## 7. CI Workflow
The `.github/workflows/dbt-ci.yml` workflow runs dbt parsing on pushes and pull requests targeting `main`. It is a CI validation step, not a Snowflake deployment. Check the GitHub Actions run log after pushing changes.

## 8. Production Deployment
Production deployment has not been configured or tested. Before enabling deployment automation:
- Provision a dedicated non-human service identity.
- Select and configure an approved authentication method.
- Grant only the minimum required privileges to the deployment role.
- Store credentials as protected GitHub Actions secrets or use an approved keyless identity integration.
- Test in a non-production environment first.
- Require review/approval before production changes.

Do not use personal credentials or ACCOUNTADMIN for automated production deployment.

## 9. Incident and Recovery Notes
If access is unexpectedly denied, verify the active role, warehouse, database/schema grants and object ownership before changing permissions. If PII appears unmasked to an unauthorized role, suspend access to the view and review its role conditions and grants before restoring access.

## 10. Evidence
Store sanitized screenshots, query outputs and GitHub Actions run results in `evidence/`. Never include passwords, tokens, private keys or real customer PII.
