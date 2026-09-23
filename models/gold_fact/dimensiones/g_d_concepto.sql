{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'dimension']
) }}

with conceptos_utilizados as (

    select distinct
        case
            when TABLA_ORIGEN = 'L4_FACT_AIGUA'
             and TIPUS_CONCEPTE is not null
                then 'AIGUA:' || TIPUS_CONCEPTE

            when TABLA_ORIGEN = 'L4_FACT_CONCEPTE'
             and NUM_CONCEPTE is not null
                then 'CONCEPTE:' || NUM_CONCEPTE

            else 'DESCONOCIDO'
        end as CODIGO_CONCEPTO,

        case
            when TABLA_ORIGEN = 'L4_FACT_AIGUA'
                then TIPUS_CONCEPTE
            when TABLA_ORIGEN = 'L4_FACT_CONCEPTE'
                then NUM_CONCEPTE
        end as CODIGO_ORIGEN,

        DESC_CONCEPTE as DESCRIPCION,
        TABLA_ORIGEN

    from {{ ref('s_factura_concepto') }}

),

catalogo as (

    select
        'CONCEPTE:' || NUM_CONCEPTE as CODIGO_CONCEPTO,
        DESC_BREU_CONCEPTE as DESCRIPCION_BREVE
    from {{ ref('s_concepto') }}

),

clasificacion as (

    select
        CODIGO_CONCEPTO,
        CODIGO_ORIGEN,
        TABLA_ORIGEN,
        GRUPO_FUNCIONAL,
        ES_CONSUMO,
        ES_SERVICIO,
        ES_TRIBUTO,
        ES_BONIFICACION,
        ES_IVA,
        ES_ADITIVO
    from {{ ref('g_s_concepto_clasificacion') }}

),

dimension as (

    select
        c.CODIGO_CONCEPTO,
        c.CODIGO_ORIGEN,
        c.DESCRIPCION,
        coalesce(
            cat.DESCRIPCION_BREVE,
            c.DESCRIPCION
        ) as DESCRIPCION_BREVE,
        coalesce(cl.GRUPO_FUNCIONAL, 'OTROS')
            as GRUPO_FUNCIONAL,
        coalesce(cl.ES_CONSUMO, false)
            as ES_CONSUMO,
        coalesce(cl.ES_SERVICIO, false)
            as ES_SERVICIO,
        coalesce(cl.ES_TRIBUTO, false)
            as ES_TRIBUTO,
        coalesce(cl.ES_BONIFICACION, false)
            as ES_BONIFICACION,
        coalesce(cl.ES_IVA, false)
            as ES_IVA,
        coalesce(cl.ES_ADITIVO, true)
            as ES_ADITIVO,
        c.TABLA_ORIGEN
    from conceptos_utilizados c
    left join catalogo cat
        on cat.CODIGO_CONCEPTO = c.CODIGO_CONCEPTO
    left join clasificacion cl
        on cl.CODIGO_CONCEPTO = c.CODIGO_CONCEPTO

)

select
    CODIGO_CONCEPTO,
    CODIGO_ORIGEN,
    DESCRIPCION,
    DESCRIPCION_BREVE,
    GRUPO_FUNCIONAL,
    ES_CONSUMO,
    ES_SERVICIO,
    ES_TRIBUTO,
    ES_BONIFICACION,
    ES_IVA,
    ES_ADITIVO,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    TABLA_ORIGEN
from dimension

union all

select
    'DESCONOCIDO',
    'DESCONOCIDO',
    'Concepto desconocido',
    'Desconocido',
    'OTROS',
    false,
    false,
    false,
    false,
    false,
    true,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    'GOLD'