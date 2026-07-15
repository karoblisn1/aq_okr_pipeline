create or replace view ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_USAGE_OKR_OVERALL(
	MONTH,
	MONTHLY_RATIO,
	YTD_RATIO
) as

WITH product_month_data AS (
    SELECT
        av.month,
        av.access_volumes_redistributed,
        au.active_users_mau
    FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_VOLUMES_REDISTRIBUTED av
    JOIN ELS_RP_WS_PROD.IDENTITY_ANALYTICS.identity_usage au
        ON  au.product_name = av.product_name
        AND au.month         = av.month
    WHERE av.product_name IN (
        'ScienceDirect',
        'eBooks+',
        'Scopus',
        'Mendeley ',
        'Complete Anatomy',
        'SIM/Skills',
        'Evolve',
        'HESI',
        'ClinicalKey (CK)',
        'ClinicalKey AI'
    )
    AND av.month between '2026-01-01' and '2026-05-31'
),

monthly_agg AS (
    SELECT
        month,
        AVG(access_volumes_redistributed) AS avg_monthly_access,
        AVG(active_users_mau)             AS avg_monthly_users
    FROM product_month_data
    GROUP BY month
)

SELECT
    month,
    ROUND(avg_monthly_access / avg_monthly_users * 100000, 2) AS monthly_ratio,
    ROUND(
        AVG(avg_monthly_access) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        /
        AVG(avg_monthly_users)  OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        * 100000,
        2
    ) AS ytd_ratio
FROM monthly_agg
ORDER BY month;