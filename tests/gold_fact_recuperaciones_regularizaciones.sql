{{ config(
    severity='error',
    store_failures=true,
    tags=['gold_fact', 'reconciliation', 'recuperaciones', 'regularizaciones']
) }}

with recuperaciones as (
    select
        s.HK_FACTURA_RECUP,
        s.HK_FACTURA,
        s.NUM_PARTICIO,
        s.M3_TOTAL_RECUPERADOS,
        s.IMP_TOTAL_RECUPERACION,
        g.HK_FACTURA as GOLD_HK_FACTURA,
        g.NUM_PARTICIO as GOLD_NUM_PARTICIO,
        g.M3_TOTAL_RECUPERADOS as GOLD_M3_TOTAL_RECUPERADOS,
        g.IMP_TOTAL_RECUPERACION as GOLD_IMP_TOTAL_RECUPERACION
    from {{ ref('s_factura_recup') }} s
    full outer join {{ ref('g_h_recuperacion') }} g
        on g.HK_FACTURA_RECUP = s.HK_FACTURA_RECUP
),
regularizaciones as (
    select
        s.HK_FACTURA_REGUL,
        s.HK_FACTURA,
        s.NUM_PARTICIO,
        s.DATA_FIN_PER_INCID,
        s.M3_TOTAL_REGULARIZADOS,
        s.IMP_TOTAL_REGULARIZACION,
        g.HK_FACTURA as GOLD_HK_FACTURA,
        g.NUM_PARTICIO as GOLD_NUM_PARTICIO,
        g.DATA_FIN_PER_INCID as GOLD_DATA_FIN_PER_INCID,
        g.M3_TOTAL_REGULARIZADOS as GOLD_M3_TOTAL_REGULARIZADOS,
        g.IMP_TOTAL_REGULARIZACION as GOLD_IMP_TOTAL_REGULARIZACION
    from {{ ref('s_factura_regul') }} s
    full outer join {{ ref('g_h_regularizacion') }} g
        on g.HK_FACTURA_REGUL = s.HK_FACTURA_REGUL
),
failures as (
    select
        'RECUPERACION' as TIPO,
        HK_FACTURA_RECUP as CLAVE,
        HK_FACTURA,
        GOLD_HK_FACTURA,
        NUM_PARTICIO,
        GOLD_NUM_PARTICIO,
        M3_TOTAL_RECUPERADOS as SILVER_VOLUMEN,
        GOLD_M3_TOTAL_RECUPERADOS as GOLD_VOLUMEN,
        IMP_TOTAL_RECUPERACION as SILVER_IMPORTE,
        GOLD_IMP_TOTAL_RECUPERACION as GOLD_IMPORTE
    from recuperaciones
    where HK_FACTURA_RECUP is null
       or GOLD_HK_FACTURA is null
       or NUM_PARTICIO <> GOLD_NUM_PARTICIO
       or abs(coalesce(M3_TOTAL_RECUPERADOS, 0) - coalesce(GOLD_M3_TOTAL_RECUPERADOS, 0)) > 0.000001
       or abs(coalesce(IMP_TOTAL_RECUPERACION, 0) - coalesce(GOLD_IMP_TOTAL_RECUPERACION, 0)) > 0.01

    union all

    select
        'REGULARIZACION',
        HK_FACTURA_REGUL,
        HK_FACTURA,
        GOLD_HK_FACTURA,
        NUM_PARTICIO,
        GOLD_NUM_PARTICIO,
        M3_TOTAL_REGULARIZADOS,
        GOLD_M3_TOTAL_REGULARIZADOS,
        IMP_TOTAL_REGULARIZACION,
        GOLD_IMP_TOTAL_REGULARIZACION
    from regularizaciones
    where HK_FACTURA_REGUL is null
       or GOLD_HK_FACTURA is null
       or NUM_PARTICIO <> GOLD_NUM_PARTICIO
       or DATA_FIN_PER_INCID <> GOLD_DATA_FIN_PER_INCID
       or abs(coalesce(M3_TOTAL_REGULARIZADOS, 0) - coalesce(GOLD_M3_TOTAL_REGULARIZADOS, 0)) > 0.000001
       or abs(coalesce(IMP_TOTAL_REGULARIZACION, 0) - coalesce(GOLD_IMP_TOTAL_REGULARIZACION, 0)) > 0.01
)
select * from failures
