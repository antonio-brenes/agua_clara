{{ config(
    severity='error',
    store_failures=true,
    tags=['gold_fact', 'consistency']
) }}

with water_totals as (
    select
        HK_FACTURA,
        sum(IMP_CONCEPTE) as IMP_AGUA_IVA,
        sum(iff(TIPUS_CONCEPTE like 'AIGUA_BLOC%', coalesce(QUANTITAT, 0), 0)) as CONSUM_TOTAL_M3
    from {{ ref('g_h_factura_concepto') }}
    where TABLA_ORIGEN = 'L4_FACT_AIGUA'
    group by HK_FACTURA
),
all_totals as (
    select HK_FACTURA, sum(IMP_CONCEPTE) as IMP_TOTAL_FACT
    from {{ ref('g_h_factura_concepto') }}
    group by HK_FACTURA
),
checks as (
    select
        'AGUA' as CONTROL,
        f.HK_FACTURA,
        f.IMP_AIGUA_IVA as EXPECTED_VALUE,
        coalesce(w.IMP_AGUA_IVA, 0) as ACTUAL_VALUE,
        f.CONSUM_TOTAL_M3 as EXPECTED_VOLUME,
        coalesce(w.CONSUM_TOTAL_M3, 0) as ACTUAL_VOLUME
    from {{ ref('g_h_factura') }} f
    left join water_totals w on w.HK_FACTURA = f.HK_FACTURA
    where abs(coalesce(f.IMP_AIGUA_IVA, 0) - coalesce(w.IMP_AGUA_IVA, 0)) > 0.01
       or abs(coalesce(f.CONSUM_TOTAL_M3, 0) - coalesce(w.CONSUM_TOTAL_M3, 0)) > 0.000001

    union all

    select
        'TOTAL',
        f.HK_FACTURA,
        f.IMP_TOTAL_FACT,
        coalesce(a.IMP_TOTAL_FACT, 0),
        null,
        null
    from {{ ref('g_h_factura') }} f
    left join all_totals a on a.HK_FACTURA = f.HK_FACTURA
    where abs(coalesce(f.IMP_TOTAL_FACT, 0) - coalesce(a.IMP_TOTAL_FACT, 0)) > 0.01

    union all

    select
        'FACTURA_CI_CONCEPTO_AGUA',
        c.HK_FACTURA,
        0,
        count(*),
        null,
        null
    from {{ ref('g_h_factura_concepto') }} c
    inner join {{ ref('g_h_factura') }} f on f.HK_FACTURA = c.HK_FACTURA
    where f.TIP_SUBM_SERV = 'C'
      and c.TABLA_ORIGEN = 'L4_FACT_AIGUA'
    group by c.HK_FACTURA
)
select * from checks
