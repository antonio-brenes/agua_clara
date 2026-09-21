{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['TIP_CODI', 'CLAU_CODI'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_codificacions') }}
)

select
    COALESCE(NULLIF(TRIM(raw."TIP_CODI"), ''), '^^') AS TIP_CODI,
    COALESCE(NULLIF(TRIM(raw."CLAU_CODI"), ''), '^^') AS CLAU_CODI,
    COALESCE(NULLIF(TRIM(raw."DESC_CODI"), ''), '^^') AS DESC_CODI,
    COALESCE(NULLIF(TRIM(raw."DESC_BREU"), ''), '^^') AS DESC_BREU,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_CODIFICACIONS' AS TABLA_ORIGEN
from raw
