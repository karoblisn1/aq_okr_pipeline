create or replace view ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_USAGE_OKR(
	PRODUCT_NAME,
	ACCESS_VOLUMES,
	ACCESS_VOLUMES_REDISTRIBUTED,
	ACTIVE_USERS_MAU,
	MONTH,
	RATIO
) as
select  av.product_name,
        av.access_volumes,
        av.access_volumes_redistributed, 
        au.active_users_mau, 
        av.month,
        round(av.access_volumes_redistributed / au.active_users_mau * 100000, 2) as ratio
from ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_VOLUMES_REDISTRIBUTED av
full join ELS_RP_WS_PROD.IDENTITY_ANALYTICS.identity_usage au
on au.product_name = av.product_name
and au.month = av.month
where av.product_name in ('ScienceDirect', 'eBooks+', 'Scopus', 'Mendeley ', 'Complete Anatomy', 'SIM/Skills', 'Evolve', 'HESI', 'ClinicalKey (CK)', 'ClinicalKey AI', 'ClinicalKey - EHE', 'Social Science Research Network (SSRN)', 'Upgraded Sherpath', 'LeapSpace', 'Osmosis')
order by product_name;