{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'bridge']
) }}

select distinct
    l.HK_SUBMIN_SERVEI,
    l.HK_HIST_SS_PE,
    h.TIP_COLECTIVO,
    h.TS_MOM_IND,
    s.DATA_INI_IND,
    s.DATA_FIN_IND,
    s.OBSERVACIONS,
    'EDW_L_SUBMIN_HIST_SS_PE + EDW_S_HIST_SS_PE' as TABLA_ORIGEN
from {{ ref('edw_l_submin_hist_ss_pe') }} l
inner join {{ ref('edw_h_hist_ss_pe') }} h
    on h.HK_HIST_SS_PE = l.HK_HIST_SS_PE
left join {{ ref('edw_s_hist_ss_pe') }} s
    on s.HK_HIST_SS_PE = h.HK_HIST_SS_PE
qualify row_number() over (
    partition by l.HK_SUBMIN_SERVEI, l.HK_HIST_SS_PE
    order by s.FECHA_CARGA desc nulls last, s.ID_CARGA desc nulls last
) = 1
