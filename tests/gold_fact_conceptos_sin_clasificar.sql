{{ config(
    severity='error',
    tags=['gold_fact', 'classification']
) }}

with conceptos_utilizados as (

    select distinct
        case
            when TABLA_ORIGEN = 'L4_FACT_AIGUA'
                then 'AIGUA:' || TIPUS_CONCEPTE
            when TABLA_ORIGEN = 'L4_FACT_CONCEPTE'
                then 'CONCEPTE:' || NUM_CONCEPTE
        end as CODIGO_CONCEPTO
    from {{ ref('s_factura_concepto') }}

),

clasificados as (

    select CODIGO_CONCEPTO
    from {{ ref('g_s_concepto_clasificacion') }}

)

select u.CODIGO_CONCEPTO
from conceptos_utilizados u
left join clasificados c
    on c.CODIGO_CONCEPTO = u.CODIGO_CONCEPTO
where u.CODIGO_CONCEPTO is not null
  and c.CODIGO_CONCEPTO is null