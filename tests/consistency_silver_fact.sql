{{ config(
    severity='error',
    store_failures=true,
    tags=['consistency', 'consistency_silver_fact']
) }}

/*
    Validaciones internas de consistencia de SILVER_FACT.

    Este test singular devuelve exclusivamente controles fallidos.
    Si todas las validaciones son correctas, la consulta devuelve cero filas.

    Reglas:
      1. CONSUM_TOTAL_M3 de S_FACTURA debe coincidir con la suma de QUANTITAT
         de los cinco conceptos AIGUA_BLOCn.
      2. IMP_AIGUA_IVA debe coincidir con la suma de los conceptos derivados
         de L4_FACT_AIGUA.
      3. IMP_TOTAL_FACT debe coincidir con la suma de conceptos de agua y
         conceptos explicitos de la factura.
*/

with

facturas as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        CONSUM_TOTAL_M3,
        IMP_AIGUA_IVA,
        IMP_TOTAL_FACT
    from {{ ref('s_factura') }}
),

consumo_conceptos as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        round(sum(coalesce(QUANTITAT, 0)), 6) as CONSUM_TOTAL_M3
    from {{ ref('s_factura_concepto') }}
    where TIPUS_CONCEPTE in (
        'AIGUA_BLOC1',
        'AIGUA_BLOC2',
        'AIGUA_BLOC3',
        'AIGUA_BLOC4',
        'AIGUA_BLOC5'
    )
    group by ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO
),

importes_agua as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        round(sum(coalesce(IMP_CONCEPTE, 0)), 2) as IMPORTE_AGUA
    from {{ ref('s_factura_concepto') }}
    where TABLA_ORIGEN = 'L4_FACT_AIGUA'
    group by ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO
),

importes_totales as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        round(sum(coalesce(IMP_CONCEPTE, 0)), 2) as IMPORTE_TOTAL_CONCEPTOS
    from {{ ref('s_factura_concepto') }}
    group by ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO
),

controles as (

    select
        'FACTURA_CONSUMO_TOTAL_DISTINTO' as CONTROL,
        f.ID_EMPRESA,
        f.ANY_FACTURA,
        f.NUM_FACTURA,
        f.NUM_PARTICIO,
        round(coalesce(f.CONSUM_TOTAL_M3, 0), 6) as VALOR_FACTURA,
        round(coalesce(c.CONSUM_TOTAL_M3, 0), 6) as VALOR_CONCEPTOS,
        round(coalesce(c.CONSUM_TOTAL_M3, 0) - coalesce(f.CONSUM_TOTAL_M3, 0), 6) as DIFERENCIA,
        'Consumo total de cabecera frente a suma de cantidades de AIGUA_BLOC1 a AIGUA_BLOC5' as DETALLE
    from facturas as f
    left join consumo_conceptos as c
        on c.ID_EMPRESA = f.ID_EMPRESA
       and c.ANY_FACTURA = f.ANY_FACTURA
       and c.NUM_FACTURA = f.NUM_FACTURA
       and c.NUM_PARTICIO = f.NUM_PARTICIO
    where abs(coalesce(c.CONSUM_TOTAL_M3, 0) - coalesce(f.CONSUM_TOTAL_M3, 0)) > 0.000001

    union all

    select
        'FACTURA_IMPORTE_AGUA_DISTINTO',
        f.ID_EMPRESA,
        f.ANY_FACTURA,
        f.NUM_FACTURA,
        f.NUM_PARTICIO,
        round(coalesce(f.IMP_AIGUA_IVA, 0), 2),
        round(coalesce(a.IMPORTE_AGUA, 0), 2),
        round(coalesce(a.IMPORTE_AGUA, 0) - coalesce(f.IMP_AIGUA_IVA, 0), 2),
        'IMP_AIGUA_IVA de cabecera frente a suma de conceptos derivados de L4_FACT_AIGUA'
    from facturas as f
    left join importes_agua as a
        on a.ID_EMPRESA = f.ID_EMPRESA
       and a.ANY_FACTURA = f.ANY_FACTURA
       and a.NUM_FACTURA = f.NUM_FACTURA
       and a.NUM_PARTICIO = f.NUM_PARTICIO
    where abs(coalesce(a.IMPORTE_AGUA, 0) - coalesce(f.IMP_AIGUA_IVA, 0)) > 0.01

    union all

    select
        'FACTURA_IMPORTE_TOTAL_DISTINTO',
        f.ID_EMPRESA,
        f.ANY_FACTURA,
        f.NUM_FACTURA,
        f.NUM_PARTICIO,
        round(coalesce(f.IMP_TOTAL_FACT, 0), 2),
        round(coalesce(t.IMPORTE_TOTAL_CONCEPTOS, 0), 2),
        round(coalesce(t.IMPORTE_TOTAL_CONCEPTOS, 0) - coalesce(f.IMP_TOTAL_FACT, 0), 2),
        'IMP_TOTAL_FACT de cabecera frente a suma de todos los conceptos normalizados'
    from facturas as f
    left join importes_totales as t
        on t.ID_EMPRESA = f.ID_EMPRESA
       and t.ANY_FACTURA = f.ANY_FACTURA
       and t.NUM_FACTURA = f.NUM_FACTURA
       and t.NUM_PARTICIO = f.NUM_PARTICIO
    where abs(coalesce(t.IMPORTE_TOTAL_CONCEPTOS, 0) - coalesce(f.IMP_TOTAL_FACT, 0)) > 0.01

)

select *
from controles
