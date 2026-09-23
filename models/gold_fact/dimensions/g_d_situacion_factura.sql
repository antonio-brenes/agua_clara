{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
select HK_SITUACION_FACT,TIP_SIT_FACT,DESC_SITUACION,DESC_BREU_SITUACION,
       ID_CARGA,FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,
       SISTEMA_ORIGEN,'S_SITUACION_FACTURA' TABLA_ORIGEN
from {{ ref('s_situacion_factura') }}
union all
select sha2_hex('SITUACION|DESCONOCIDA',256),'DESCONOCIDO','Desconocida','Desc.',0,null,
       convert_timezone('Europe/Madrid',current_timestamp()),'GOLD','S_SITUACION_FACTURA'
