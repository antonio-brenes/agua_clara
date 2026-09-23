{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with x as (
 select h.HK_EPIGRAF_IAE,h.SECCIO,h.EPIGRAF_IAE,s.DESCR_IAE,s.TIP_TARIFA,s.TIP_QUOTA_TAMGREM,s.NIV_GEN_RES,s.COD_GEN_RES,
        s.ID_CARGA,s.FECHA_EXTRACCION,s.SISTEMA_ORIGEN,
        row_number() over(partition by h.HK_EPIGRAF_IAE order by s.FECHA_CARGA desc nulls last,s.FECHA_EXTRACCION desc nulls last,s.ID_CARGA desc nulls last) RN
 from {{ ref('edw_h_epigraf_iae') }} h left join {{ ref('edw_s_epigraf_iae') }} s on s.HK_EPIGRAF_IAE=h.HK_EPIGRAF_IAE
)
select HK_EPIGRAF_IAE as HK_ACTIVIDAD_ECONOMICA,HK_EPIGRAF_IAE,SECCIO,EPIGRAF_IAE,DESCR_IAE,TIP_TARIFA,TIP_QUOTA_TAMGREM,NIV_GEN_RES,COD_GEN_RES,
       ID_CARGA,FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,SISTEMA_ORIGEN,'EDW_S_EPIGRAF_IAE' TABLA_ORIGEN
from x where RN=1
union all select sha2_hex('ACTIVIDAD|DESCONOCIDA',256),sha2_hex('EPIGRAF|DESCONOCIDO',256),'D','DESCONOCIDO','Desconocida',null,null,null,null,0,null,
convert_timezone('Europe/Madrid',current_timestamp()),'GOLD','EDW_S_EPIGRAF_IAE'
