{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_submin_iae') }}
)

select
    NULLIF(TRIM(raw."POLISSA_SUBM"), '') AS POLISSA_SUBM,
    NULLIF(TRIM(raw."SECCIO"), '') AS SECCIO,
    NULLIF(TRIM(raw."EPIGRAF_IAE"), '') AS EPIGRAF_IAE,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_SUBMIN_IAE' AS TABLA_ORIGEN
from raw
