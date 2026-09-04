{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_epigraf_iae') }}
)

select
    NULLIF(TRIM(raw."SECCIO"), '') AS SECCIO,
    NULLIF(TRIM(raw."EPIGRAF_IAE"), '') AS EPIGRAF_IAE,
    NULLIF(TRIM(raw."DESCR_IAE"), '') AS DESCR_IAE,
    NULLIF(TRIM(raw."TIP_TARIFA"), '') AS TIP_TARIFA,
    NULLIF(TRIM(raw."TIP_QUOTA_TAMGREM"), '') AS TIP_QUOTA_TAMGREM,
    NULLIF(TRIM(raw."NIV_GEN_RES"), '') AS NIV_GEN_RES,
    NULLIF(TRIM(raw."COD_GEN_RES"), '') AS COD_GEN_RES,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_EPIGRAF_IAE' AS TABLA_ORIGEN
from raw
