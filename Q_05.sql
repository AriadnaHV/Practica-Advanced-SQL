-- =====================================================
-- 5. GENERATE document_type AND document_identification
-- =====================================================
SELECT ivr_id,
       document_identification,
       document_type
FROM (
    SELECT CAST(calls_ivr_id AS STRING) AS ivr_id,
           document_identification,
           document_type,
           module_sequece,
           step_sequence,
           IF(document_identification NOT IN ('UNKNOWN', 'DESCONOCIDO'), 1, 0) AS has_document_lg
    FROM keepcoding.ivr_detail
    QUALIFY ROW_NUMBER() OVER(
        PARTITION BY CAST(calls_ivr_id AS STRING)
        ORDER BY has_document_lg DESC, module_sequece DESC, step_sequence DESC
    ) = 1
);