-- ===========================================================
-- 11. GENERATE repeated_phone_24H AND cause_recall_phone_24H
-- ===========================================================
SELECT calls.calls_ivr_id,
       MAX(IF(DATE_DIFF(calls.calls_start_date, recalls.calls_start_date, SECOND) BETWEEN 1 AND 24*60*60, 1, 0)) AS repeated_phone_24H,
       MAX(IF(DATE_DIFF(calls.calls_start_date, recalls.calls_start_date, SECOND) BETWEEN -24*60*60 AND -1, 1, 0)) AS cause_recall_phone_24H
FROM keepcoding.ivr_detail calls
LEFT JOIN keepcoding.ivr_detail recalls
       ON calls.calls_phone_number <> 'UNKNOWN'
      AND calls.calls_phone_number = recalls.calls_phone_number
      AND calls.calls_ivr_id <> recalls.calls_ivr_id
GROUP BY calls.calls_ivr_id;