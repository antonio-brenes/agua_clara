{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['SECCIO', 'EPIGRAF_IAE'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_epigraf_iae') }}
)

select
    COALESCE(NULLIF(TRIM(raw."SECCIO"), ''), '^^') AS SECCIO,
    COALESCE(NULLIF(TRIM(raw."EPIGRAF_IAE"), ''), '^^') AS EPIGRAF_IAE,
    COALESCE(NULLIF(TRIM(raw."DESCR_IAE"), ''), '^^') AS DESCR_IAE,
    COALESCE(NULLIF(TRIM(raw."TIP_TARIFA"), ''), '^^') AS TIP_TARIFA,
    COALESCE(NULLIF(TRIM(raw."TIP_QUOTA_TAMGREM"), ''), '^^') AS TIP_QUOTA_TAMGREM,
    COALESCE(NULLIF(TRIM(raw."NIV_GEN_RES"), ''), '^^') AS NIV_GEN_RES,
    COALESCE(NULLIF(TRIM(raw."COD_GEN_RES"), ''), '^^') AS COD_GEN_RES,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_EPIGRAF_IAE' AS TABLA_ORIGEN
from raw
