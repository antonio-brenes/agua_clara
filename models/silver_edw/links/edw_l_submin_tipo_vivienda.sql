{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'link']
) }}
with source_data as (
    select
        upper(trim(POLISSA_SUBM)) as POLISSA_SUBM,
        upper(trim(TIP_HABIT_SUBM)) as COD_TIPO_VIVIENDA,
        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN
    from {{ ref('l4_submin_servei') }}
    where nullif(trim(POLISSA_SUBM), '') is not null
      and nullif(trim(TIP_HABIT_SUBM), '') is not null
),
hashed_source as (
    select
        sha2_hex(concat_ws('|', POLISSA_SUBM, COD_TIPO_VIVIENDA), 256) as HK_SUBMIN_TIPO_VIVIENDA,
        sha2_hex(POLISSA_SUBM, 256) as HK_SUBMIN_SERVEI,
        sha2_hex(COD_TIPO_VIVIENDA, 256) as HK_TIPO_VIVIENDA,
        POLISSA_SUBM,
        COD_TIPO_VIVIENDA,
        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN
    from source_data
)
select
    src.HK_SUBMIN_TIPO_VIVIENDA,
    src.HK_SUBMIN_SERVEI,
    src.HK_TIPO_VIVIENDA,
    src.POLISSA_SUBM,
    src.COD_TIPO_VIVIENDA,
    src.ID_CARGA,
    src.FECHA_EXTRACCION,
    convert_timezone('Europe/Madrid', current_timestamp()) as FECHA_CARGA,
    src.SISTEMA_ORIGEN,
    'L4_SUBMIN_SERVEI' as TABLA_ORIGEN
from hashed_source src
{% if is_incremental() %}
where not exists (
    select 1 from {{ this }} tgt
    where tgt.HK_SUBMIN_TIPO_VIVIENDA = src.HK_SUBMIN_TIPO_VIVIENDA
)
{% endif %}
