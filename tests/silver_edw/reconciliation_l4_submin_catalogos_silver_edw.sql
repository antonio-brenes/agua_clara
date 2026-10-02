{{ config(severity='error', store_failures=true, tags=['reconciliation','reconciliation_l4_silver_edw']) }}
select 'TIPO_SUMINISTRO' OBJECT_NAME,e.HK_LINK,e.BUSINESS_KEY
from (select distinct sha2_hex(concat_ws('|',upper(trim(POLISSA_SUBM)),upper(trim(TIP_SUBM_SERV))),256) HK_LINK,
             concat_ws('|',upper(trim(POLISSA_SUBM)),upper(trim(TIP_SUBM_SERV))) BUSINESS_KEY
      from {{ ref('l4_submin_servei') }} where nullif(trim(POLISSA_SUBM),'') is not null and nullif(trim(TIP_SUBM_SERV),'') is not null) e
left join (select HK_SUBMIN_TIPO_SUMINISTRO HK_LINK from {{ ref('edw_l_submin_tipo_suministro') }}) a using(HK_LINK)
where a.HK_LINK is null
union all
select 'TIPO_USO_AGUA' OBJECT_NAME,e.HK_LINK,e.BUSINESS_KEY
from (select distinct sha2_hex(concat_ws('|',upper(trim(POLISSA_SUBM)),upper(trim(US_AIGUA_SUBM))),256) HK_LINK,
             concat_ws('|',upper(trim(POLISSA_SUBM)),upper(trim(US_AIGUA_SUBM))) BUSINESS_KEY
      from {{ ref('l4_submin_servei') }} where nullif(trim(POLISSA_SUBM),'') is not null and nullif(trim(US_AIGUA_SUBM),'') is not null) e
left join (select HK_SUBMIN_TIPO_USO_AGUA HK_LINK from {{ ref('edw_l_submin_tipo_uso_agua') }}) a using(HK_LINK)
where a.HK_LINK is null
union all
select 'TIPO_VIVIENDA' OBJECT_NAME,e.HK_LINK,e.BUSINESS_KEY
from (select distinct sha2_hex(concat_ws('|',upper(trim(POLISSA_SUBM)),upper(trim(TIP_HABIT_SUBM))),256) HK_LINK,
             concat_ws('|',upper(trim(POLISSA_SUBM)),upper(trim(TIP_HABIT_SUBM))) BUSINESS_KEY
      from {{ ref('l4_submin_servei') }} where nullif(trim(POLISSA_SUBM),'') is not null and nullif(trim(TIP_HABIT_SUBM),'') is not null) e
left join (select HK_SUBMIN_TIPO_VIVIENDA HK_LINK from {{ ref('edw_l_submin_tipo_vivienda') }}) a using(HK_LINK)
where a.HK_LINK is null
