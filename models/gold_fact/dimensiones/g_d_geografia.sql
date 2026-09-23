{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'dimension']
) }}

with candidates as (
    select
        sr.HK_SUBMIN_SERVEI,
        m.HK_MUNICIPI_SGAB,
        m.NUM_MUN_SGAB,
        c.HK_CARRER,
        c.NUM_CARRER,
        f.HK_FINCA,
        f.NUM_INI_FINCA,
        f.COMP_NUM_INI_FINCA,
        f.NUM_FIN_FINCA,
        f.COMP_NUM_FIN_FINCA,
        fs.NUM_DTE_MUNI_FINCA,
        ms.NOM_MUN_SGAB,
        cs.NOM_COMPLET_CARRER,
        row_number() over (
            partition by sr.HK_SUBMIN_SERVEI
            order by f.HK_FINCA, c.HK_CARRER, m.HK_MUNICIPI_SGAB,
                fs.FECHA_CARGA desc nulls last,
                cs.FECHA_CARGA desc nulls last,
                ms.FECHA_CARGA desc nulls last
        ) as RN
    from {{ ref('edw_l_submin_ramal') }} sr
    inner join {{ ref('edw_l_finca_ramal') }} fr
        on fr.HK_RAMAL = sr.HK_RAMAL
    inner join {{ ref('edw_l_carrer_finca') }} cf
        on cf.HK_FINCA = fr.HK_FINCA
    inner join {{ ref('edw_l_municipi_carrer') }} mc
        on mc.HK_CARRER = cf.HK_CARRER
    inner join {{ ref('edw_h_municipi_sgab') }} m
        on m.HK_MUNICIPI_SGAB = mc.HK_MUNICIPI_SGAB
    inner join {{ ref('edw_h_carrer') }} c
        on c.HK_CARRER = cf.HK_CARRER
    inner join {{ ref('edw_h_finca') }} f
        on f.HK_FINCA = fr.HK_FINCA
    left join {{ ref('edw_s_municipi_sgab') }} ms
        on ms.HK_MUNICIPI_SGAB = m.HK_MUNICIPI_SGAB
    left join {{ ref('edw_s_carrer') }} cs
        on cs.HK_CARRER = c.HK_CARRER
    left join {{ ref('edw_s_finca') }} fs
        on fs.HK_FINCA = f.HK_FINCA
)

select
    HK_SUBMIN_SERVEI,
    HK_MUNICIPI_SGAB,
    NUM_MUN_SGAB,
    HK_CARRER,
    NUM_CARRER,
    HK_FINCA,
    NUM_INI_FINCA,
    COMP_NUM_INI_FINCA,
    NUM_FIN_FINCA,
    COMP_NUM_FIN_FINCA,
    NUM_DTE_MUNI_FINCA,
    NOM_MUN_SGAB,
    NOM_COMPLET_CARRER,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    'EDW_H_MUNICIPI_SGAB + EDW_H_CARRER + EDW_H_FINCA' as TABLA_ORIGEN
from candidates
where RN = 1
