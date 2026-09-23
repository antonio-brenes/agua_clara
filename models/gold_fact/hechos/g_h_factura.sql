{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA',
    schema='gold_fact',
    tags=['gold_fact', 'fact']
) }}

with conceptos as (
    select
        HK_FACTURA,
        count(*) as NUM_CONCEPTOS
    from {{ ref('s_factura_concepto') }}
    group by HK_FACTURA
),

facturas as (
    select
        f.HK_FACTURA,
        f.HK_SUBMIN_SERVEI,
        f.HK_TIPO_SUMINISTRO,
        f.HK_TIPO_USO_AGUA,
        f.HK_TIPO_VIVIENDA,
        f.ID_EMPRESA,
        f.ANY_FACTURA,
        f.NUM_FACTURA,
        f.NUM_PARTICIO,
        f.POLISSA_SUBM,
        f.DATA_INI_FACT,
        f.DATA_FIN_FACT,
        f.DATA_EMISS_FACT,
        f.DATA_CARREC_RECAP,
        f.ANY_CALENDARI,
        f.MES_CALENDARI,
        f.FREQ_FACT,
        f.DIES_FACTURATS,
        f.TIP_SUBM_SERV,
        f.US_AIGUA_SUBM_FACT,
        f.TIP_HABIT_SUBM_FA,
        f.NOMB_HABIT_FACT,
        f.SIT_SUBM_SERV_FACT,
        f.TIP_DOMESTIC,
        f.CONSUM_TOTAL_M3,
        f.IMP_TOTAL_FACT,
        f.IMP_AIGUA_IVA,
        f.ID_RECUPERACIO,
        f.ID_REGULARITZACIO,
        f.ID_CONCEPTES,
        f.TIP_FACTURA,
        f.TIPUS_FACTURA,
        f.QL_TIP_COBRA,
        f.DNI_NIF_CLIENT,
        f.NOM_CLIENT,
        f.ID_CARGA,
        f.FECHA_EXTRACCION,
        f.SISTEMA_ORIGEN,
        f.TABLA_ORIGEN,
        coalesce(c.NUM_CONCEPTOS, 0) as NUM_CONCEPTOS
    from {{ ref('s_factura') }} f
    left join conceptos c
        on c.HK_FACTURA = f.HK_FACTURA
)

select
    f.HK_FACTURA,
    f.HK_SUBMIN_SERVEI,
    f.HK_TIPO_SUMINISTRO,
    f.HK_TIPO_USO_AGUA,
    f.HK_TIPO_VIVIENDA,
    f.ID_EMPRESA,
    f.ANY_FACTURA,
    f.NUM_FACTURA,
    f.NUM_PARTICIO,
    f.POLISSA_SUBM,
    f.DATA_INI_FACT,
    f.DATA_FIN_FACT,
    f.DATA_EMISS_FACT,
    f.DATA_CARREC_RECAP,
    f.ANY_CALENDARI,
    f.MES_CALENDARI,
    f.FREQ_FACT,
    f.DIES_FACTURATS,
    f.TIP_SUBM_SERV,
    f.US_AIGUA_SUBM_FACT,
    f.TIP_HABIT_SUBM_FA,
    f.NOMB_HABIT_FACT,
    f.SIT_SUBM_SERV_FACT,
    f.TIP_DOMESTIC,
    f.CONSUM_TOTAL_M3,
    f.IMP_TOTAL_FACT,
    f.IMP_AIGUA_IVA,
    f.NUM_CONCEPTOS,
    iff(f.ID_RECUPERACIO is not null, true, false) as TIENE_RECUPERACION,
    iff(f.ID_REGULARITZACIO is not null, true, false) as TIENE_REGULARIZACION,
    iff(exists (
        select 1 from {{ ref('g_b_suministro_actividad') }} a
        where a.HK_SUBMIN_SERVEI = f.HK_SUBMIN_SERVEI
          and a.ES_ACTIVIDAD_INDUSTRIAL_PRINCIPAL
    ), true, false) as TIENE_ACTIVIDAD_INDUSTRIAL,
    iff(exists (
        select 1 from {{ ref('g_b_suministro_colectivo') }} s
        where s.HK_SUBMIN_SERVEI = f.HK_SUBMIN_SERVEI
          and s.DATA_INI_IND <= f.DATA_FIN_FACT
          and (s.DATA_FIN_IND is null or f.DATA_FIN_FACT <= s.DATA_FIN_IND)
    ), true, false) as ES_VULNERABLE,
    iff(exists (
        select 1
        from {{ ref('edw_l_submin_conveni_frau') }} l
        inner join {{ ref('edw_s_conveni_frau') }} s
            on s.HK_CONVENI_FRAU = l.HK_CONVENI_FRAU
        where l.HK_SUBMIN_SERVEI = f.HK_SUBMIN_SERVEI
          and s.DATA_CREA_C_FRA <= f.DATA_FIN_FACT
    ), true, false) as ES_FRAUDULENTA,
    f.ID_CARGA,
    f.FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    f.SISTEMA_ORIGEN,
    'S_FACTURA' as TABLA_ORIGEN
from facturas f
