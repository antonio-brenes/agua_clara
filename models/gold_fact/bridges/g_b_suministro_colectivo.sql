{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','bridge']) }}
select distinct l.HK_SUBMIN_SERVEI,sha2_hex('COLECTIVO|'||upper(trim(h.TIP_COLECTIVO)),256) HK_COLECTIVO,l.HK_HIST_SS_PE,
       h.TIP_COLECTIVO,h.TS_MOM_IND,s.DATA_INI_IND,s.DATA_FIN_IND,s.OBSERVACIONS,
       l.ID_CARGA,l.FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,
       l.SISTEMA_ORIGEN,'EDW_L_SUBMIN_HIST_SS_PE' TABLA_ORIGEN
from {{ ref('edw_l_submin_hist_ss_pe') }} l join {{ ref('edw_h_hist_ss_pe') }} h on h.HK_HIST_SS_PE=l.HK_HIST_SS_PE
left join {{ ref('edw_s_hist_ss_pe') }} s on s.HK_HIST_SS_PE=h.HK_HIST_SS_PE
qualify row_number() over(partition by l.HK_SUBMIN_SERVEI,l.HK_HIST_SS_PE order by s.FECHA_CARGA desc nulls last,s.ID_CARGA desc nulls last)=1
