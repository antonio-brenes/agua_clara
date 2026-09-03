{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_situacio_fact') }}
)

select
    TRY_TO_DECIMAL(NULLIF(TRIM(raw."NUM_PARTICIO"), ''), 2, 0) AS NUM_PARTICIO,
    NULLIF(TRIM(raw."ID_EMPRESA"), '') AS ID_EMPRESA,
    NULLIF(TRIM(raw."ANY_FACTURA"), '') AS ANY_FACTURA,
    TRY_TO_DECIMAL(NULLIF(TRIM(raw."NUM_FACTURA"), ''), 7, 0) AS NUM_FACTURA,
    TRY_TO_TIMESTAMP_NTZ(NULLIF(TRIM(raw."MOM_SIT_FACT"), '')) AS MOM_SIT_FACT,
    NULLIF(TRIM(raw."TIP_SIT_FACT"), '') AS TIP_SIT_FACT,
    NULLIF(TRIM(raw."CAUSA_SIT_FACT"), '') AS CAUSA_SIT_FACT,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_SITUACIO_FACT' AS TABLA_ORIGEN
from raw
