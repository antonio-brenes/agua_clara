{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_dte_municipal') }}
)

select
    NULLIF(TRIM(raw."NUM_MUN_SGAB"), '') AS NUM_MUN_SGAB,
    NULLIF(TRIM(raw."NUM_DTE_MUNI"), '') AS NUM_DTE_MUNI,
    NULLIF(TRIM(raw."NOM_DTE_MUNI"), '') AS NOM_DTE_MUNI,
    NULLIF(TRIM(raw."NUM_DEL_SGAB"), '') AS NUM_DEL_SGAB,
    NULLIF(TRIM(raw."NUM_AGENCIA_SGAB"), '') AS NUM_AGENCIA_SGAB,
    NULLIF(TRIM(raw."CODI_AREA_SD"), '') AS CODI_AREA_SD,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_DTE_MUNICIPAL' AS TABLA_ORIGEN
from raw
