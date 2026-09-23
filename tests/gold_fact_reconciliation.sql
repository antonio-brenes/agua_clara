{{ config(
    severity='error',
    store_failures=true,
    tags=['gold_fact', 'reconciliation', 'reconciliation_silver_gold']
) }}

with controls as (
    select
        'FACTURAS' as CONTROL,
        (select count(*) from {{ ref('s_factura') }}) as SILVER_COUNT,
        (select count(*) from {{ ref('g_h_factura') }}) as GOLD_COUNT,
        (select coalesce(sum(IMP_TOTAL_FACT), 0) from {{ ref('s_factura') }}) as SILVER_VALUE,
        (select coalesce(sum(IMP_TOTAL_FACT), 0) from {{ ref('g_h_factura') }}) as GOLD_VALUE
    union all
    select
        'CONCEPTOS',
        (select count(*) from {{ ref('s_factura_concepto') }}),
        (select count(*) from {{ ref('g_h_factura_concepto') }}),
        (select coalesce(sum(IMP_CONCEPTE), 0) from {{ ref('s_factura_concepto') }}),
        (select coalesce(sum(IMP_CONCEPTE), 0) from {{ ref('g_h_factura_concepto') }})
    union all
    select
        'RECUPERACIONES',
        (select count(*) from {{ ref('s_factura_recup') }}),
        (select count(*) from {{ ref('g_h_recuperacion') }}),
        (select coalesce(sum(IMP_TOTAL_RECUPERACION), 0) from {{ ref('s_factura_recup') }}),
        (select coalesce(sum(IMP_TOTAL_RECUPERACION), 0) from {{ ref('g_h_recuperacion') }})
    union all
    select
        'REGULARIZACIONES',
        (select count(*) from {{ ref('s_factura_regul') }}),
        (select count(*) from {{ ref('g_h_regularizacion') }}),
            (select coalesce(sum(IMP_TOTAL_REGULARIZACION), 0) from {{ ref('s_factura_regul') }}),
            (select coalesce(sum(IMP_TOTAL_REGULARIZACION), 0) from {{ ref('g_h_regularizacion') }})
),
failures as (
    select *, GOLD_COUNT - SILVER_COUNT as COUNT_DIFFERENCE, GOLD_VALUE - SILVER_VALUE as VALUE_DIFFERENCE
    from controls
    where GOLD_COUNT <> SILVER_COUNT
       or abs(GOLD_VALUE - SILVER_VALUE) > 0.01
)
select * from failures
