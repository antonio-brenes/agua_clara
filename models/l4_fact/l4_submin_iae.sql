{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['POLISSA_SUBM', 'SECCIO', 'EPIGRAF_IAE'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_submin_iae') }}
)

select
    COALESCE(NULLIF(TRIM(raw."POLISSA_SUBM"), ''), '^^') AS POLISSA_SUBM,
    COALESCE(NULLIF(TRIM(raw."SECCIO"), ''), '^^') AS SECCIO,
    COALESCE(NULLIF(TRIM(raw."EPIGRAF_IAE"), ''), '^^') AS EPIGRAF_IAE,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_SUBMIN_IAE' AS TABLA_ORIGEN
from raw
