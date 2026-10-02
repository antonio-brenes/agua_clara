{{ config(
    materialized='table',
    schema='silver_fact',
    tags=['silver_fact', 'maestro', 'facturacion']
) }}

with catalogo_f25 as (

    select distinct
        upper(trim(clau_codi)) as num_concepto,
        upper(trim(desc_codi)) as desc_concepto,
        upper(trim(desc_breu)) as desc_breve_concepto,
        id_carga,
        fecha_extraccion,
        sistema_origen,
        'L4_CODIFICACIONS' as tabla_origen

    from {{ ref('l4_codificacions') }}
    where tip_codi = 'F25'
      and upper(trim(clau_codi)) not in ('CL1','CL2')

),

catalogo_aigua as (

    select
        num_concepto,
        desc_concepto,
        desc_breve_concepto,
        -1 as id_carga,
        null as fecha_extraccion,
        'SILVER_FACT' as sistema_origen,
        'S_CONCEPTO' as tabla_origen
    from {{ ref('s_seed_conceptos_agua') }}

),

catalogo as (

    select * from catalogo_f25

    union all

    select * from catalogo_aigua

),

clasificacion as (

    select *
    from {{ ref('s_seed_clasificacion_conceptos') }}

)

select
    sha2_hex(c.num_concepto, 256) as hk_concepto,

    c.num_concepto,
    c.desc_concepto,
    c.desc_breve_concepto,

    cl.grupo_funcional,
    cl.es_consumo,
    cl.es_servicio,
    cl.es_tributo,
    cl.es_bonificacion,
    cl.es_iva,
    cl.es_aditivo,

    c.id_carga,
    c.fecha_extraccion,
    convert_timezone('Europe/Madrid', current_timestamp()) as fecha_carga,
    c.sistema_origen,
    c.tabla_origen

from catalogo c
left join clasificacion cl
    on c.num_concepto = cl.num_concepto