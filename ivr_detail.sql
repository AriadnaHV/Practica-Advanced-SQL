-- How many modules do not have a call?
SELECT COUNT(*) AS modules_without_call
FROM keepcoding.ivr_modules as mod
LEFT JOIN keepcoding.ivr_calls as cal 
ON mod.ivr_id = cal.ivr_id
WHERE cal.ivr_id IS NULL;

-- How many steps per module, on average? And how many distinct calls?
SELECT
    COUNT(mod.module_sequece) AS total_modules,
    COUNT(DISTINCT mod.module_sequece) AS distinct_modules,
    AVG(COALESCE(ste.ste_count,0)) AS avg_steps_per_module
FROM keepcoding.ivr_modules as mod
LEFT JOIN (
    SELECT module_sequece, COUNT(*) AS ste_count
    FROM keepcoding.ivr_steps
    GROUP BY module_sequece
) as ste 
ON ste.module_sequece = mod.module_sequece;

--To create the table, I am using OUTER JOIN in order to retrieve all details from the other tables,
--and not ignore the potential NULL fields.

CREATE TABLE keepcoding.ivr_detail AS

WITH date_ids AS (
    SELECT
        cal.start_date,
        DATE(cal.start_date) AS start_date_id,  --if leaving as "date"
        --FORMAT_DATE('%Y%m%d', DATE(cal.start_date)) AS start_date_id, --if changing to "string"
        cal.end_date,
        DATE(cal.end_date) AS end_date_id,  --if leaving as "date"
        --FORMAT_DATE('%Y%m%d', DATE(cal.end_date)) AS end_date_id, --if changing to "string"
        cal.ivr_id
    FROM keepcoding.ivr_calls as cal
)
SELECT
    cal.ivr_id,
    cal.phone_number,
    cal.ivr_result,
    cal.vdn_label,
    cal.start_date,
    start_date_id,
    cal.end_date,
    end_date_id,
    cal.total_duration,
    cal.customer_segment,
    cal.ivr_language,
    cal.steps_module,
    cal.module_aggregation,
    mod.module_sequece,
    mod.module_name,
    mod.module_duration,
    mod.module_result,
    ste.step_sequence,
    ste.step_name,
    ste.step_result,
    ste.step_description_error,
    ste.document_type,
    ste.document_identification,
    ste.customer_phone,
    ste.billing_account_id    
FROM keepcoding.ivr_calls as cal
FULL OUTER JOIN date_ids 
    ON cal.ivr_id = date_ids.ivr_id
FULL OUTER JOIN keepcoding.ivr_modules as mod
    ON cal.ivr_id = mod.ivr_id
FULL OUTER JOIN keepcoding.ivr_steps as ste
    ON cal.ivr_id = ste.ivr_id;

--The created table, ivr_detail, contains 1,909,080 rows.
--The original tables, contained the following number of rows:
    -- ivr_calls:    21,674 rows
    -- ivr_modules: 133,599 rows
    -- ivr_steps:   293,349 rows