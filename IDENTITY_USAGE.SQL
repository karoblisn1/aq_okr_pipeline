create or replace view ELS_RP_WS_PROD.IDENTITY_ANALYTICS.IDENTITY_USAGE(
	PRODUCT_NAME,
	MONTH,
	ACTIVE_USERS_MAU
) as
WITH union_identity AS (
    SELECT
        product_name,
        TO_VARCHAR(combined_user_id) AS user_id,
        date_of_event::timestamp_ntz AS dt
    FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.NEOID_REPORTING_SESSIONS_AGG_NEW neo_id
    WHERE DATE(date_of_event) >= '2025-05-01'
      AND user_type LIKE 'External'
      AND auth_type IN (
        'CLIENT_LOGIN',
        'FEDERATED_IDENTITY_LINK',
        'IDENTITY_PROVIDER_FIRST_LOGIN',
        'IDENTITY_PROVIDER_POST_LOGIN',
        'KEYCLOAK',
        'LOGIN',
        'REGISTER',
        'TOKEN_EXCHANGE',
        's', 'scoa', 'seacft', 'sepft', 'sertft', 'ssa'
      )
      AND (
        type IS NULL OR type IN (
          'CLIENT_LOGIN',
          'CODE_TO_TOKEN',
          'FEDERATED_IDENTITY_LINK',
          'IDENTITY_PROVIDER_FIRST_LOGIN',
          'IDENTITY_PROVIDER_POST_LOGIN',
          'LOGIN',
          'OAUTH2_DEVICE_CODE_TO_TOKEN',
          'REFRESH_TOKEN',
          'REGISTER',
          'RESTART_AUTHENTICATION',
          'REVOKE_GRANT',
          'TOKEN_EXCHANGE',
          'USER_INFO_REQUEST'
        )
      )
      AND product_name NOT IN ('ClinicalKey (CK)')
    UNION ALL
    SELECT
        product_name,
        TO_VARCHAR(web_user_id) AS user_id,
        last_login_date::timestamp_ntz AS dt
    FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ID_PLUS_DASHBOARD_DATA_DEDUP
    WHERE last_login_date >= '2025-01-01'
      AND product_name NOT IN ('ClinicalKey AI', 'Admin Console', 'Evolve')
),
identity_mau AS (
    SELECT
        product_name,
        DATE_TRUNC('month', dt) AS month,
        COUNT(DISTINCT user_id) AS active_users_mau
    FROM union_identity
    GROUP BY 1, 2
),
evolve_mau_dedup AS (
    SELECT DISTINCT
        product_name,
        month::timestamp_ntz AS month,
        active_users_mau
    FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.EVOLVE_MAU
),
hesi_mau_dedup AS (
    SELECT DISTINCT
        product_name,
        month::timestamp_ntz AS month,
        active_users_mau
    FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.HESI_MAU
),
simskills_mau_dedup AS (
    SELECT DISTINCT
        product_name,
        month::timestamp_ntz AS month,
        active_users_mau
    FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.SIMSKILLS_MAU
),
sherpath_mau_dedup AS (
    SELECT DISTINCT
        product_name,
        month::timestamp_ntz AS month,
        active_users_mau
    FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.SHERPATH_MAU
)
SELECT product_name, month, active_users_mau FROM identity_mau
UNION ALL
SELECT product_name, month, active_users_mau FROM evolve_mau_dedup
UNION ALL
SELECT product_name, month, active_users_mau FROM hesi_mau_dedup
UNION ALL
SELECT product_name, month, active_users_mau FROM simskills_mau_dedup
UNION ALL
SELECT product_name, month, active_users_mau FROM sherpath_mau_dedup;