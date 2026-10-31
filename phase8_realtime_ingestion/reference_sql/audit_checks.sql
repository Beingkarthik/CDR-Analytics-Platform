SELECT
    COUNT(*) AS current_scd_rows
FROM dim_fraud_labels
WHERE scd_current_flag = TRUE;

SELECT
    fraud_id,
    COUNT(*) AS versions
FROM dim_fraud_labels
GROUP BY fraud_id
HAVING COUNT(*) > 1
ORDER BY versions DESC;
