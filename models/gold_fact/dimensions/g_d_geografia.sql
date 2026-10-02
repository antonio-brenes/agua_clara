{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with base as (
    select fh.HK_FINCA, fh.NUM_INI_FINCA, fh.COMP_NUM_INI_FINCA, fh.NUM_FIN_FINCA, fh.COMP_NUM_FIN_FINCA,
           ch.HK_CARRER, ch.NUM_CARRER, mh.HK_MUNICIPI_SGAB, mh.NUM_MUN_SGAB,
           fs.NUM_DTE_MUNI_FINCA, ms.NOM_MUN_SGAB, cs.NOM_COMPLET_CARRER,
           fs.ID_CARGA, fs.FECHA_EXTRACCION, fs.SISTEMA_ORIGEN,
           row_number() over (partition by fh.HK_FINCA order by fs.FECHA_CARGA desc nulls last, fs.FECHA_EXTRACCION desc nulls last, fs.ID_CARGA desc nulls last,
                              cs.FECHA_CARGA desc nulls last, ms.FECHA_CARGA desc nulls last) as RN
    from {{ ref('edw_h_finca') }} fh
    left join {{ ref('edw_s_finca') }} fs on fs.HK_FINCA = fh.HK_FINCA
    left join {{ ref('edw_l_carrer_finca') }} cfl on cfl.HK_FINCA = fh.HK_FINCA
    left join {{ ref('edw_h_carrer') }} ch on ch.HK_CARRER = cfl.HK_CARRER
    left join {{ ref('edw_s_carrer') }} cs on cs.HK_CARRER = ch.HK_CARRER
    left join {{ ref('edw_l_municipi_carrer') }} mcl on mcl.HK_CARRER = ch.HK_CARRER
    left join {{ ref('edw_h_municipi_sgab') }} mh on mh.HK_MUNICIPI_SGAB = mcl.HK_MUNICIPI_SGAB
    left join {{ ref('edw_s_municipi_sgab') }} ms on ms.HK_MUNICIPI_SGAB = mh.HK_MUNICIPI_SGAB
)
select HK_FINCA as HK_GEOGRAFIA, HK_FINCA, HK_CARRER, HK_MUNICIPI_SGAB, NUM_MUN_SGAB, NOM_MUN_SGAB,
       NUM_CARRER, NOM_COMPLET_CARRER, NUM_INI_FINCA, COMP_NUM_INI_FINCA, NUM_FIN_FINCA, COMP_NUM_FIN_FINCA, NUM_DTE_MUNI_FINCA,
       ID_CARGA, FECHA_EXTRACCION, convert_timezone('Europe/Madrid',current_timestamp()) as FECHA_CARGA,
       SISTEMA_ORIGEN, 'EDW_S_FINCA' as TABLA_ORIGEN
from base where RN = 1
union all
select sha2_hex('DESCONOCIDO', 256), sha2_hex('DESCONOCIDO', 256), null, null, null, 'Desconocido', null, 'Desconocido', null, null, null, null, null,
       -1, null, convert_timezone('Europe/Madrid', current_timestamp()), 'GOLD', 'EDW_S_FINCA'
