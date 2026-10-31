SELECT
t.table_name,
COUNT(c.column_name) AS column_count,

MAX(CASE
WHEN tc.constraint_type = 'PRIMARY KEY'
THEN kcu.column_name
END) AS pk_column,

COUNT(CASE
WHEN tc.constraint_type = 'FOREIGN KEY'
THEN 1
END) AS fk_count,

BOOL_OR(c.column_name = 'scd_current_flag') AS has_scd_flag

FROM information_schema.tables t

JOIN information_schema.columns c
ON c.table_name = t.table_name
AND c.table_schema = t.table_schema

LEFT JOIN information_schema.table_constraints tc
ON tc.table_name = t.table_name
AND tc.table_schema = t.table_schema

LEFT JOIN information_schema.key_column_usage kcu
ON kcu.constraint_name = tc.constraint_name
AND kcu.table_schema = tc.table_schema

WHERE t.table_schema = 'public'
AND t.table_type = 'BASE TABLE'

GROUP BY t.table_name
ORDER BY t.table_name;
