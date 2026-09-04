{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_codificacions') }}
)

select
    NULLIF(TRIM(raw."TIP_CODI"), '') AS TIP_CODI,
    NULLIF(TRIM(raw."CLAU_CODI"), '') AS CLAU_CODI,
    NULLIF(TRIM(raw."DESC_CODI"), '') AS DESC_CODI,
    NULLIF(TRIM(raw."DESC_BREU"), '') AS DESC_BREU,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_CODIFICACIONS' AS TABLA_ORIGEN
from raw
