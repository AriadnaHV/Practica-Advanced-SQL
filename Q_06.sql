-- =====================================================
-- 6. GENERATE customer_phone
-- =====================================================
SELECT calls_ivr_id,
       IFNULL(MAX(NULLIF(customer_phone, 'UNKNOWN')), 'DESCONOCIDO') AS customer_phone
FROM keepcoding.ivr_detail
GROUP BY calls_ivr_id;