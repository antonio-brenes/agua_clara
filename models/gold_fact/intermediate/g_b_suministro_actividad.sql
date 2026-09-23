{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'bridge']
) }}

select distinct
    l.HK_SUBMIN_SERVEI,
    l.HK_EPIGRAF_IAE,
    h.SECCIO,
    h.EPIGRAF_IAE,
    s.DESCR_IAE,
    iff(h.SECCIO = 'I', true, false) as ES_ACTIVIDAD_INDUSTRIAL_PRINCIPAL,
    iff(h.SECCIO = 'S', true, false) as ES_ACTIVIDAD_SERVICIOS_SECUNDARIA,
    'EDW_L_SUBMIN_IAE + EDW_S_EPIGRAF_IAE' as TABLA_ORIGEN
from {{ ref('edw_l_submin_iae') }} l
inner join {{ ref('edw_h_epigraf_iae') }} h
    on h.HK_EPIGRAF_IAE = l.HK_EPIGRAF_IAE
left join {{ ref('edw_s_epigraf_iae') }} s
    on s.HK_EPIGRAF_IAE = h.HK_EPIGRAF_IAE
qualify row_number() over (
    partition by l.HK_SUBMIN_SERVEI, l.HK_EPIGRAF_IAE
    order by s.FECHA_CARGA desc nulls last, s.ID_CARGA desc nulls last
) = 1
