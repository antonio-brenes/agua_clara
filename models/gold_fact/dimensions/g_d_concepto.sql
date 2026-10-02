{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact','dimension']
) }}

with conceptos as (

    select
        hk_concepto,
        num_concepto,
        desc_concepto,
        desc_breve_concepto,

        grupo_funcional,
        es_consumo,
        es_servicio,
        es_tributo,
        es_bonificacion,
        es_iva,
        es_aditivo,

        tabla_origen as origen_concepto,

        id_carga,
        fecha_extraccion,
        sistema_origen

    from {{ ref('s_concepto') }}

)

select
    hk_concepto,
    num_concepto,
    desc_concepto,
    desc_breve_concepto,

    grupo_funcional,
    es_consumo,
    es_servicio,
    es_tributo,
    es_bonificacion,
    es_iva,
    es_aditivo,

    origen_concepto,

    id_carga,
    fecha_extraccion,
    convert_timezone('Europe/Madrid', current_timestamp()) as fecha_carga,
    sistema_origen,
    'S_CONCEPTO' as tabla_origen

from conceptos

union all

select
    sha2_hex('DESCONOCIDO',256),
    '?',
    'Desconocido',
    'Desconocido',

    'OTROS',
    false,
    false,
    false,
    false,
    false,
    true,

    'GOLD',

    -1,
    null,
    convert_timezone('Europe/Madrid', current_timestamp()),
    'GOLD_FACT',
    'G_D_CONCEPTO'
