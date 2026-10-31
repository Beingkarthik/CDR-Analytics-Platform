-- ============================================================
-- schema_ddl.sql
-- Phase 2: Data Modelling & Schema Design
-- Project: Telecom Data Engineering
-- 360DigiTMG | AiSPRY — Data Engineering Mentor Program
-- Target: PostgreSQL 15+
-- Run order: dimensions first, then facts
-- ============================================================

-- ============================================================
-- DROP TABLES (clean run on fresh instance)
-- ============================================================
DROP TABLE IF EXISTS fact_switch_reconciliation CASCADE;
DROP TABLE IF EXISTS fact_roaming_events        CASCADE;
DROP TABLE IF EXISTS fact_rated_cdrs            CASCADE;
DROP TABLE IF EXISTS fact_cdr_events            CASCADE;
DROP TABLE IF EXISTS dim_fraud_labels           CASCADE;
DROP TABLE IF EXISTS dim_fraud_simulation_patterns CASCADE;
DROP TABLE IF EXISTS dim_tariff_tables          CASCADE;
DROP TABLE IF EXISTS dim_subscriber_plans       CASCADE;
DROP TABLE IF EXISTS dim_date                   CASCADE;

-- ============================================================
-- 1. dim_date  (required in every project)
-- ============================================================
CREATE TABLE dim_date (
    date_key        INTEGER      NOT NULL,   -- YYYYMMDD surrogate key
    full_date       DATE         NOT NULL,
    year            SMALLINT     NOT NULL,
    quarter         SMALLINT     NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    month           SMALLINT     NOT NULL CHECK (month BETWEEN 1 AND 12),
    month_name      VARCHAR(9)   NOT NULL,
    week_number     SMALLINT     NOT NULL CHECK (week_number BETWEEN 1 AND 53),
    day_of_week     SMALLINT     NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    day_name        VARCHAR(9)   NOT NULL,
    is_weekend      BOOLEAN      NOT NULL DEFAULT FALSE,
    is_holiday      BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
);

-- Populate dim_date for 2022-01-01 to 2026-12-31
INSERT INTO dim_date (
    date_key, full_date, year, quarter, month, month_name,
    week_number, day_of_week, day_name, is_weekend, is_holiday
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER                         AS date_key,
    d::DATE                                                  AS full_date,
    EXTRACT(YEAR  FROM d)::SMALLINT                          AS year,
    EXTRACT(QUARTER FROM d)::SMALLINT                        AS quarter,
    EXTRACT(MONTH FROM d)::SMALLINT                          AS month,
    TO_CHAR(d, 'Month')                                      AS month_name,
    EXTRACT(WEEK  FROM d)::SMALLINT                          AS week_number,
    EXTRACT(ISODOW FROM d)::SMALLINT                         AS day_of_week,
    TO_CHAR(d, 'Day')                                        AS day_name,
    EXTRACT(ISODOW FROM d) IN (6,7)                          AS is_weekend,
    FALSE                                                    AS is_holiday   -- update via holiday table
FROM GENERATE_SERIES('2022-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) AS d;

-- ============================================================
-- 2. dim_subscriber_plans  (source: subscriber_plans.csv)
--    SCD Type 2: NOT REQUIRED — versioning handled via new plan_id
-- ============================================================
CREATE TABLE dim_subscriber_plans (
    plan_sk                     SERIAL       NOT NULL,   -- surrogate key
    plan_id                     VARCHAR(10)  NOT NULL,   -- business key (e.g. PLN001)
    plan_name                   VARCHAR(100) NOT NULL,
    plan_category               VARCHAR(20)  NOT NULL,   -- Prepay/Postpay/Business/IoT/Wholesale/Legacy/Internal
    rate_per_minute_pence       NUMERIC(8,4) NOT NULL,
    data_rate_per_mb_pence      NUMERIC(8,4) NOT NULL,
    sms_rate_pence              NUMERIC(8,4) NOT NULL,
    monthly_fee_gbp             NUMERIC(10,2),           -- nullable: 4 plans have no fee
    free_voice_minutes          INTEGER      NOT NULL DEFAULT 0,
    free_data_gb                NUMERIC(8,3),            -- nullable: 3 plans have no data allowance
    free_sms_count              INTEGER      NOT NULL DEFAULT 0,
    roaming_rate_multiplier     NUMERIC(6,4) NOT NULL DEFAULT 1.0,
    international_rate_multiplier NUMERIC(6,4) NOT NULL DEFAULT 1.0,
    peak_rate_multiplier        NUMERIC(6,4) NOT NULL DEFAULT 1.0,
    off_peak_rate_multiplier    NUMERIC(6,4) NOT NULL DEFAULT 1.0,
    valid_from                  DATE         NOT NULL,
    valid_to                    DATE         NOT NULL,
    CONSTRAINT pk_dim_subscriber_plans PRIMARY KEY (plan_sk),
    CONSTRAINT uq_dim_subscriber_plans_bk UNIQUE (plan_id)
);

-- ============================================================
-- 3. dim_tariff_tables  (source: tariff_tables.csv)
--    SCD Type 2: NOT REQUIRED — rate changes produce new tariff_id
-- ============================================================
CREATE TABLE dim_tariff_tables (
    tariff_sk               SERIAL       NOT NULL,   -- surrogate key
    tariff_id               VARCHAR(10)  NOT NULL,   -- business key (e.g. TAR00001)
    destination_type        VARCHAR(20)  NOT NULL,   -- domestic/international/premium/satellite
    destination_country     VARCHAR(60)  NOT NULL,
    country_code            VARCHAR(5)   NOT NULL,
    number_prefix           VARCHAR(20),             -- nullable: 83.5% null (routing via country_code)
    rate_per_minute_pence   NUMERIC(8,4) NOT NULL,
    rate_per_mb_pence       NUMERIC(8,4) NOT NULL,
    sms_rate_pence          NUMERIC(8,4) NOT NULL,
    time_band               VARCHAR(10)  NOT NULL,   -- Peak / Off-Peak
    day_type                VARCHAR(10)  NOT NULL,   -- Weekday / Weekend
    peak_start              TIME         NOT NULL,
    peak_end                TIME         NOT NULL,
    is_premium_rate         SMALLINT     NOT NULL DEFAULT 0 CHECK (is_premium_rate IN (0,1)),
    surcharge_pence         NUMERIC(8,4) NOT NULL DEFAULT 0,
    description             VARCHAR(200),
    valid_from              DATE         NOT NULL,
    valid_to                DATE         NOT NULL,
    CONSTRAINT pk_dim_tariff_tables PRIMARY KEY (tariff_sk),
    CONSTRAINT uq_dim_tariff_tables_bk UNIQUE (tariff_id)
);

-- ============================================================
-- 4. dim_fraud_simulation_patterns  (source: fraud_simulation_patterns.csv)
--    SCD Type 2: NOT REQUIRED — pattern versioning managed by ML pipeline
-- ============================================================
CREATE TABLE dim_fraud_simulation_patterns (
    pattern_sk                  SERIAL       NOT NULL,   -- surrogate key
    pattern_id                  VARCHAR(10)  NOT NULL,   -- business key (e.g. PAT0001)
    fraud_type                  VARCHAR(50)  NOT NULL,
    pattern_name                VARCHAR(200) NOT NULL,
    linked_subscriber_id        VARCHAR(20),             -- nullable: may not link to a known subscriber
    avg_call_duration_seconds   NUMERIC(8,2) NOT NULL,
    call_volume_per_hour        NUMERIC(8,2) NOT NULL,
    destination_range_count     INTEGER      NOT NULL,
    inter_call_gap_seconds      NUMERIC(8,2) NOT NULL,
    international_call_pct      NUMERIC(6,2) NOT NULL,
    detection_threshold_score   NUMERIC(6,4) NOT NULL CHECK (detection_threshold_score BETWEEN 0 AND 1),
    min_calls_to_trigger        INTEGER      NOT NULL,
    window_size_minutes         INTEGER      NOT NULL,
    feature_voice_volume        SMALLINT     NOT NULL DEFAULT 0 CHECK (feature_voice_volume IN (0,1)),
    feature_dest_entropy        SMALLINT     NOT NULL DEFAULT 0 CHECK (feature_dest_entropy IN (0,1)),
    feature_duration_std        SMALLINT     NOT NULL DEFAULT 0 CHECK (feature_duration_std IN (0,1)),
    feature_intl_ratio          SMALLINT     NOT NULL DEFAULT 0 CHECK (feature_intl_ratio IN (0,1)),
    feature_gap_regularity      SMALLINT     NOT NULL DEFAULT 0 CHECK (feature_gap_regularity IN (0,1)),
    confirmed_fraud_flag        SMALLINT     NOT NULL DEFAULT 0 CHECK (confirmed_fraud_flag IN (0,1)),
    first_seen_date             DATE         NOT NULL,
    last_seen_date              DATE         NOT NULL,
    notes                       TEXT,
    CONSTRAINT pk_dim_fraud_simulation_patterns PRIMARY KEY (pattern_sk),
    CONSTRAINT uq_dim_fraud_simulation_patterns_bk UNIQUE (pattern_id)
);

-- ============================================================
-- 5. dim_fraud_labels  (source: fraud_labels.csv)
--    SCD TYPE 2 REQUIRED — fraud status & financial impact change
--    over time as investigations are re-opened or overturned.
-- ============================================================
CREATE TABLE dim_fraud_labels (
    fraud_label_sk          SERIAL       NOT NULL,   -- surrogate key (unique per SCD version)
    fraud_id                VARCHAR(15)  NOT NULL,   -- business key (e.g. FRD000001)
    subscriber_id           VARCHAR(20)  NOT NULL,
    fraud_type              VARCHAR(50)  NOT NULL,
    detection_date          DATE         NOT NULL,
    confirmed_date          DATE,                    -- nullable: suspected cases not yet confirmed
    confirmation_method     VARCHAR(50)  NOT NULL,
    financial_impact_gbp    NUMERIC(12,2) NOT NULL,
    account_suspended       SMALLINT     NOT NULL DEFAULT 0 CHECK (account_suspended IN (0,1)),
    status                  VARCHAR(30)  NOT NULL,
    notes                   TEXT,                    -- nullable: optional analyst free-text
    scd_version             SMALLINT     NOT NULL,
    -- SCD Type 2 control columns
    scd_effective_start     DATE         NOT NULL,
    scd_effective_end       DATE,                    -- NULL = current active version
    scd_current_flag        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_dim_fraud_labels PRIMARY KEY (fraud_label_sk)
);

-- Partial unique index: only one current version per fraud case
CREATE UNIQUE INDEX uix_dim_fraud_labels_current
    ON dim_fraud_labels (fraud_id)
    WHERE scd_current_flag = TRUE;

-- ============================================================
-- 6. fact_cdr_events  (source: cdr_records.csv)
--    Grain: one row per network call/SMS/data event per CDR
-- ============================================================
CREATE TABLE fact_cdr_events (
    cdr_event_sk                BIGSERIAL    NOT NULL,   -- surrogate key
    cdr_id                      VARCHAR(20)  NOT NULL,   -- business key
    subscriber_id               VARCHAR(20)  NOT NULL,
    plan_sk                     INTEGER      NOT NULL,
    date_key                    INTEGER      NOT NULL,   -- FK to dim_date (derived from start_timestamp)
    -- Degenerate dimensions (kept on fact for filtering without dim lookup)
    call_type                   VARCHAR(30)  NOT NULL,
    call_direction              VARCHAR(5)   NOT NULL,   -- MO / MT
    termination_cause           VARCHAR(50),
    originating_number          VARCHAR(20)  NOT NULL,
    terminating_number          VARCHAR(20),             -- nullable: MT/data/MMS
    switch_id                   VARCHAR(20)  NOT NULL,
    switch_region               VARCHAR(50)  NOT NULL,
    cell_id                     VARCHAR(20)  NOT NULL,
    rat_type                    VARCHAR(10)  NOT NULL,   -- 2G/3G/4G/5G NR
    imei                        BIGINT,
    imsi                        BIGINT,
    roaming_flag                SMALLINT     NOT NULL DEFAULT 0 CHECK (roaming_flag IN (0,1)),
    start_timestamp             TIMESTAMPTZ  NOT NULL,
    end_timestamp               TIMESTAMPTZ  NOT NULL,
    -- Measures
    duration_seconds            INTEGER      NOT NULL CHECK (duration_seconds >= 0),
    data_volume_mb              NUMERIC(10,3) NOT NULL DEFAULT 0,
    estimated_charge_pence      NUMERIC(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_fact_cdr_events PRIMARY KEY (cdr_event_sk),
    CONSTRAINT fk_fact_cdr_plan    FOREIGN KEY (plan_sk)  REFERENCES dim_subscriber_plans (plan_sk),
    CONSTRAINT fk_fact_cdr_date    FOREIGN KEY (date_key) REFERENCES dim_date (date_key),
    CONSTRAINT uq_fact_cdr_events_bk UNIQUE (cdr_id)
);

-- ============================================================
-- 7. fact_rated_cdrs  (source: rated_cdrs.csv)
--    Grain: one row per billing rating event per CDR per billing month
-- ============================================================
CREATE TABLE fact_rated_cdrs (
    rated_cdr_sk                    BIGSERIAL    NOT NULL,   -- surrogate key
    rated_id                        VARCHAR(20)  NOT NULL,   -- business key
    cdr_event_sk                    BIGINT       NOT NULL,   -- FK to fact_cdr_events
    cdr_id                          VARCHAR(20)  NOT NULL,   -- business key bridging to source CDR
    subscriber_id                   VARCHAR(20)  NOT NULL,
    plan_sk                         INTEGER      NOT NULL,
    tariff_sk                       INTEGER      NOT NULL,
    billing_date_key                INTEGER      NOT NULL,   -- FK to dim_date (first day of billing_month)
    -- Degenerate dimensions
    time_band_applied               VARCHAR(10)  NOT NULL,   -- Peak / Off-Peak
    day_type_applied                VARCHAR(10)  NOT NULL,   -- Weekday / Weekend
    call_type                       VARCHAR(30)  NOT NULL,
    rating_engine_version           VARCHAR(20)  NOT NULL,
    rating_timestamp                TIMESTAMPTZ  NOT NULL,
    -- Measures
    charge_pence                    NUMERIC(10,2) NOT NULL,
    billable_duration_seconds       NUMERIC(10,2) NOT NULL DEFAULT 0,
    applied_rate_per_minute_pence   NUMERIC(8,4)  NOT NULL,
    -- Quality flags (semi-additive)
    free_allowance_consumed_flag    SMALLINT     NOT NULL DEFAULT 0 CHECK (free_allowance_consumed_flag IN (0,1)),
    overage_flag                    SMALLINT     NOT NULL DEFAULT 0 CHECK (overage_flag IN (0,1)),
    rated_correctly_flag            SMALLINT     NOT NULL DEFAULT 1 CHECK (rated_correctly_flag IN (0,1)),
    CONSTRAINT pk_fact_rated_cdrs PRIMARY KEY (rated_cdr_sk),
    CONSTRAINT fk_rated_cdr_event   FOREIGN KEY (cdr_event_sk)   REFERENCES fact_cdr_events (cdr_event_sk),
    CONSTRAINT fk_rated_cdr_plan    FOREIGN KEY (plan_sk)        REFERENCES dim_subscriber_plans (plan_sk),
    CONSTRAINT fk_rated_cdr_tariff  FOREIGN KEY (tariff_sk)      REFERENCES dim_tariff_tables (tariff_sk),
    CONSTRAINT fk_rated_cdr_date    FOREIGN KEY (billing_date_key) REFERENCES dim_date (date_key),
    CONSTRAINT uq_fact_rated_cdrs_bk UNIQUE (rated_id)
);

-- ============================================================
-- 8. fact_roaming_events  (source: roaming_cdrs.xml / TAP3.11)
--    Grain: one row per TAP3.11 roaming event per served IMSI
-- ============================================================
CREATE TABLE fact_roaming_events (
    roaming_event_sk            BIGSERIAL    NOT NULL,   -- surrogate key
    served_imsi                 BIGINT       NOT NULL,
    served_msisdn               VARCHAR(20)  NOT NULL,
    -- Degenerate dimensions
    record_type                 VARCHAR(10)  NOT NULL,   -- MOC / MTC / GPRS / SMS
    home_network                VARCHAR(20)  NOT NULL,
    visited_network             VARCHAR(20),
    partner_code                VARCHAR(20),             -- from BatchControlInfo (e.g. DEUTE49)
    calling_number              VARCHAR(20),             -- nullable: 100% null in raw batch; filled post-parser fix
    destination_number          VARCHAR(20),             -- nullable: same
    event_date_key              INTEGER      NOT NULL,   -- FK to dim_date (derived from CallEventStartTimestamp)
    event_start_timestamp       TIMESTAMPTZ  NOT NULL,
    -- Measures
    total_call_event_duration   INTEGER      NOT NULL CHECK (total_call_event_duration >= 0),
    charge_amount               NUMERIC(10,4) NOT NULL DEFAULT 0,
    data_volume_incoming        BIGINT       NOT NULL DEFAULT 0,
    data_volume_outgoing        BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_fact_roaming_events PRIMARY KEY (roaming_event_sk),
    CONSTRAINT fk_roaming_date FOREIGN KEY (event_date_key) REFERENCES dim_date (date_key)
);

-- ============================================================
-- 9. fact_switch_reconciliation  (source: switch_reconciliation.csv)
--    Grain: one row per switch per calendar date
-- ============================================================
CREATE TABLE fact_switch_reconciliation (
    recon_sk                BIGSERIAL    NOT NULL,   -- surrogate key
    recon_id                VARCHAR(15)  NOT NULL,   -- business key (e.g. REC0000001)
    date_key                INTEGER      NOT NULL,   -- FK to dim_date
    -- Degenerate dimensions
    switch_id               VARCHAR(20)  NOT NULL,
    switch_region           VARCHAR(50)  NOT NULL,
    switch_vendor           VARCHAR(30)  NOT NULL,   -- Ericsson / Nokia / Huawei
    reconciliation_status   VARCHAR(10)  NOT NULL,   -- OK / FAIL / OUTAGE
    sla_met_flag            SMALLINT     NOT NULL DEFAULT 0 CHECK (sla_met_flag IN (0,1)),
    processed_by            VARCHAR(50)  NOT NULL,
    -- Measures
    expected_cdr_count      INTEGER      NOT NULL,
    received_cdr_count      INTEGER      NOT NULL,
    missing_count           INTEGER      NOT NULL,   -- can be negative (received > expected)
    duplicate_count         INTEGER      NOT NULL DEFAULT 0,
    malformed_count         INTEGER      NOT NULL DEFAULT 0,
    loss_rate_pct           NUMERIC(6,4) NOT NULL DEFAULT 0,
    duplicate_rate_pct      NUMERIC(6,4) NOT NULL DEFAULT 0,
    CONSTRAINT pk_fact_switch_reconciliation PRIMARY KEY (recon_sk),
    CONSTRAINT fk_recon_date FOREIGN KEY (date_key) REFERENCES dim_date (date_key),
    CONSTRAINT uq_fact_recon_bk UNIQUE (recon_id)
);

-- ============================================================
-- INDEXES (performance on common join/filter columns)
-- ============================================================

-- fact_cdr_events
CREATE INDEX idx_cdr_events_date       ON fact_cdr_events (date_key);
CREATE INDEX idx_cdr_events_subscriber ON fact_cdr_events (subscriber_id);
CREATE INDEX idx_cdr_events_plan       ON fact_cdr_events (plan_sk);
CREATE INDEX idx_cdr_events_call_type  ON fact_cdr_events (call_type);

-- fact_rated_cdrs
CREATE INDEX idx_rated_cdrs_date       ON fact_rated_cdrs (billing_date_key);
CREATE INDEX idx_rated_cdrs_subscriber ON fact_rated_cdrs (subscriber_id);
CREATE INDEX idx_rated_cdrs_plan       ON fact_rated_cdrs (plan_sk);
CREATE INDEX idx_rated_cdrs_tariff     ON fact_rated_cdrs (tariff_sk);

-- fact_roaming_events
CREATE INDEX idx_roaming_imsi          ON fact_roaming_events (served_imsi);
CREATE INDEX idx_roaming_date          ON fact_roaming_events (event_date_key);

-- fact_switch_reconciliation
CREATE INDEX idx_recon_switch          ON fact_switch_reconciliation (switch_id);
CREATE INDEX idx_recon_date            ON fact_switch_reconciliation (date_key);

-- dim_fraud_labels
CREATE INDEX idx_fraud_labels_sub      ON dim_fraud_labels (subscriber_id);
CREATE INDEX idx_fraud_labels_type     ON dim_fraud_labels (fraud_type);

-- ============================================================
-- END OF DDL
-- ============================================================
