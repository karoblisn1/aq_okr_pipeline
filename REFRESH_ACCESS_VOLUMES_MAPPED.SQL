CREATE OR REPLACE PROCEDURE ELS_RP_WS_PROD.IDENTITY_ANALYTICS.REFRESH_ACCESS_VOLUMES_MAPPED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS '
BEGIN
    TRUNCATE TABLE ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_VOLUMES_MAPPED;

    INSERT INTO ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_VOLUMES_MAPPED
    WITH products AS (
        SELECT
            "Incident Id" AS incident_id,
            "Incident Closed Datetime" AS date_time,
            COALESCE(
                "CSOTC Combined Product Level Reporting",
                "Customer Classification Product",
                ''UNKNOWN''
            ) AS dashboard_product_raw,
            CASE
                WHEN "CSOTC Combined Product Level Reporting" IS NOT NULL THEN TRUE
                ELSE FALSE
            END AS is_combined,
            CASE
                WHEN (
                    "Contact Reason Lvl1 Desc" IN (
                        ''Access'', ''Access (FR only)'', ''Login & Account'',
                        ''Online Access'', ''Sign in'', ''Using APIs'', ''Manage'',
                        ''Access/QR code'', ''Login/password'', ''Account'', ''Trial''
                    )
                    OR "Contact Reason Lvl2 Desc" IN (
                        ''Provisioning Access'', ''Authentication or access'',
                        ''System outage'', ''Insttoken'', ''Availability'',
                        ''Cannot login'', ''Access'', ''Course ID'', ''Outage'',
                        ''Registration'', ''Merge accounts'',
                        ''Enrollment/unenrollment'', ''Adoption Request''
                    )
                )
                AND "Mailbox Name" != ''Patient Access''
                THEN TRUE
                ELSE FALSE
            END AS is_access
        FROM OSVC_DB.OSVC_SCHEMA."vw_osvc_xm_access_reduction_taskforce"
        WHERE "Product Category" = ''Digital''
          AND "Incident Closed Datetime" >= ''2025-01-01 00:00:00''
          AND (
                "Incident Closed Datetime" >= ''2025-05-01 00:00:00''
                OR NOT (
                    "Customer Classification Product" IN (
                        ''Elsevier eBooks plus'', ''ClinicalKey AI'',
                        ''3D4Medical'', ''Osmosis''
                    )
                    OR "CSOTC Combined Product Level Reporting" IN (
                        ''Elsevier eBooks plus'', ''ClinicalKey AI'',
                        ''3D4Medical'', ''Osmosis''
                    )
                )
          )
          AND "CSOTC Division" IN (
                ''Clinical Solutions'', ''Data as a Service'', ''Education'',
                ''ehelpdesk'', ''Engineering Solutions'', ''Global Medical Education'',
                ''Life Sciences'', ''Mendeley'', ''SSRN''
          )
    ),
    agg AS (
        SELECT
            dashboard_product_raw,
            COUNT(incident_id) AS access_volumes,
            DATE_TRUNC(''month'', date_time) AS month,
            is_combined
        FROM products
        WHERE is_access = TRUE
        GROUP BY
            dashboard_product_raw,
            DATE_TRUNC(''month'', date_time),
            is_combined
    ),
    mapping AS (
        SELECT
            access_product_concat,
            MIN(helios_name) AS helios_name
        FROM ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ABACUS_HELIOS_PRODUCT_MAPPING
        GROUP BY access_product_concat
    )
    SELECT
        CASE
            WHEN COALESCE(m.helios_name, a.dashboard_product_raw, ''UNKNOWN'') = ''Consult''
                THEN ''eBooks+''
            ELSE COALESCE(m.helios_name, a.dashboard_product_raw, ''UNKNOWN'')
        END AS product_name,
        a.dashboard_product_raw AS abacus_name,
        a.access_volumes,
        TRUE AS is_access,
        a.month,
        a.is_combined
    FROM agg a
    LEFT JOIN mapping m
        ON a.dashboard_product_raw = m.access_product_concat;

    RETURN ''Refreshed successfully: '' || CURRENT_TIMESTAMP();
END;
';