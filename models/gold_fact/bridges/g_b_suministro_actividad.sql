{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','bridge']) }}
select distinct l.HK_SUBMIN_SERVEI,l.HK_EPIGRAF_IAE as HK_ACTIVIDAD_ECONOMICA,l.HK_EPIGRAF_IAE,
       h.SECCIO,h.EPIGRAF_IAE,iff(h.SECCIO='I',true,false) ES_ACTIVIDAD_INDUSTRIAL_PRINCIPAL,
       iff(h.SECCIO='S',true,false) ES_ACTIVIDAD_SERVICIOS_SECUNDARIA,
       l.ID_CARGA,l.FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,
       l.SISTEMA_ORIGEN,'EDW_L_SUBMIN_IAE' TABLA_ORIGEN
from {{ ref('edw_l_submin_iae') }} l join {{ ref('edw_h_epigraf_iae') }} h on h.HK_EPIGRAF_IAE=l.HK_EPIGRAF_IAE
