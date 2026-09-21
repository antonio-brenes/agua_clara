{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['NUM_MUN_SGAB', 'NUM_DTE_MUNI'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_dte_municipal') }}
)

select
    COALESCE(NULLIF(TRIM(raw."NUM_MUN_SGAB"), ''), '^^') AS NUM_MUN_SGAB,
    COALESCE(NULLIF(TRIM(raw."NUM_DTE_MUNI"), ''), '^^') AS NUM_DTE_MUNI,
    COALESCE(NULLIF(TRIM(raw."NOM_DTE_MUNI"), ''), '^^') AS NOM_DTE_MUNI,
    COALESCE(NULLIF(TRIM(raw."NUM_DEL_SGAB"), ''), '^^') AS NUM_DEL_SGAB,
    COALESCE(NULLIF(TRIM(raw."NUM_AGENCIA_SGAB"), ''), '^^') AS NUM_AGENCIA_SGAB,
    COALESCE(NULLIF(TRIM(raw."CODI_AREA_SD"), ''), '^^') AS CODI_AREA_SD,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_DTE_MUNICIPAL' AS TABLA_ORIGEN
from raw
