# Phase 10 – Governance, Security and Deployment

## Project
CDR Analytics Platform

## Objective
Document the governance, role-based access control, PII protection approach, security validation and CI workflow for the CDR Analytics Platform.

## 1. Role-Based Access Control
The Snowflake environment includes the following project roles:
- CDR_ANALYST_ROLE – analyst access
- CDR_DEV_ROLE – development access
- CDR_PROD_ROLE – production access
- CDR_SECURITY_ADMIN_ROLE – security administration
- CDR_DEPLOY_ROLE – deployment role created for future deployment automation

The role hierarchy and grants are documented in `sql/role_hierarchy.sql`. Review the actual grants in Snowflake before treating every listed permission as independently verified.

## 2. PII Protection
A secure-view masking approach was implemented and tested using synthetic customer data in `CDR_ANALYTICS.SECURITY_DEMO`.

View: `V_CUSTOMER_PII_MASKED`

The view displays masked phone and email values to the analyst role and unmasked values to the authorized security administrator role. The secure-view property was verified in Snowflake.

Native masking policies were attempted but the Snowflake account returned `Unsupported feature MASKING POLICY`. Therefore, this project uses the tested secure-view fallback; native masking policies are not implemented.

## 3. dbt Validation
The dbt project is located at `../phase8_realtime_ingestion/dbt_project`.

- `dbt parse --no-partial-parse` completed successfully.
- A development `dbt build` completed successfully with 7 passing results and no errors after the unavailable fraud-label model, snapshot and tests were temporarily disabled.
- The fraud-label pipeline remains incomplete because the expected `fraud_labels.csv` input was not present.

## 4. CI Workflow
GitHub Actions workflow: `.github/workflows/dbt-ci.yml`.

The workflow checks out the repository, installs dbt and runs `dbt parse`. It is a project-validation workflow only. It does not connect to Snowflake or deploy production models.

## 5. Production Deployment Status
Production deployment automation is not yet configured or verified. A deployment role was created, but a dedicated service identity, authentication configuration and GitHub repository secrets have not been confirmed. Do not treat the project as having completed automated production deployment.

## 6. Folder Guide
- `sql/` – inspection, role, PII design and validation SQL scripts
- `policies/` – policy documentation
- `ci_cd/` – deployment workflow draft
- `docs/` – operational runbook
- `diagrams/` – architecture and access-control diagrams
- `evidence/` – screenshots and execution evidence
- `presentation/` – presentation material
- `reports/` – final reports

## 7. Execution Notes
Run SQL scripts in Snowflake Worksheets/Workspace using an appropriately authorized role. Review each script before execution. Do not place passwords, private keys or access tokens in this repository.
