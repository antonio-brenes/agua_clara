{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
select HK_TIPO_SUMINISTRO,COD_TIPO_SUMINISTRO,DES_TIPO_SUMINISTRO,DES_ABREV_TIPO_SUMINISTRO,
       ID_CARGA,FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,
       SISTEMA_ORIGEN,'EDW_S_TIPO_SUMINISTRO' TABLA_ORIGEN
from {{ ref('edw_s_tipo_suministro') }}
qualify row_number() over(partition by HK_TIPO_SUMINISTRO order by FECHA_CARGA desc,FECHA_EXTRACCION desc,ID_CARGA desc)=1
union all
select sha2_hex('TIPO_SUMINISTRO|DESCONOCIDO',256),'DESCONOCIDO','Desconocido','Desc.',0,null,
       convert_timezone('Europe/Madrid',current_timestamp()),'GOLD','EDW_S_TIPO_SUMINISTRO'
