create or replace view ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_VOLUMES_REDISTRIBUTED(
	MONTH,
	PRODUCT_NAME,
	ACCESS_VOLUMES,
	RATIO,
	ID_REDISTRIBUTION,
	ACCESS_VOLUMES_REDISTRIBUTED
) as
with base as (
  select
    month,
    product_name,
    access_volumes,
    case
      when trim(product_name) = 'ScienceDirect'      then 0.474739812
      when trim(product_name) = 'Scopus'             then 0.211305641
      when trim(product_name) = 'ClinicalKey (CK)'   then 0.170100434
      when trim(product_name) = 'Mendeley'           then 0.143854113
      else 0
    end as ratio,
    sum(
      case when trim(product_name) = 'ID+' then access_volumes end
    ) over (partition by month) as id_total

  from ELS_RP_WS_PROD.IDENTITY_ANALYTICS.ACCESS_VOLUMES_MAPPED
)

select
  month,
  product_name,
  access_volumes,

  ratio,
  case
    when trim(product_name) in ('ScienceDirect','Scopus','Mendeley','ClinicalKey (CK)')
      then ratio * coalesce(id_total, 0)
    else 0
  end as id_redistribution,
  case
    when trim(product_name) in ('ScienceDirect','Scopus','Mendeley','ClinicalKey (CK)')
      then access_volumes + (ratio * coalesce(id_total, 0))
    else access_volumes
  end as access_volumes_redistributed

from base
order by month, product_name;