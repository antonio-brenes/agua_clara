{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
select distinct sha2_hex('COLECTIVO|'||upper(trim(TIP_COLECTIVO)),256) HK_COLECTIVO,TIP_COLECTIVO,
       'Colectivo '||TIP_COLECTIVO DESC_COLECTIVO,
       ID_CARGA,FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,SISTEMA_ORIGEN,'EDW_S_HIST_SS_PE' TABLA_ORIGEN
from {{ ref('edw_s_hist_ss_pe') }} where TIP_COLECTIVO is not null
qualify row_number() over(partition by TIP_COLECTIVO order by FECHA_CARGA desc,FECHA_EXTRACCION desc,ID_CARGA desc)=1
union all select sha2_hex('COLECTIVO|DESCONOCIDO',256),'DESCONOCIDO','Desconocido',0,null,
convert_timezone('Europe/Madrid',current_timestamp()),'GOLD','EDW_S_HIST_SS_PE'
