{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['NUM_PARTICIO', 'ID_EMPRESA', 'ANY_FACTURA', 'NUM_FACTURA', 'MOM_SIT_FACT'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_situacio_fact') }}
)

select
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NUM_PARTICIO"), ''), 2, 0), 0) AS NUM_PARTICIO,
    COALESCE(NULLIF(TRIM(raw."ID_EMPRESA"), ''), '^^') AS ID_EMPRESA,
    COALESCE(NULLIF(TRIM(raw."ANY_FACTURA"), ''), '^^') AS ANY_FACTURA,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NUM_FACTURA"), ''), 7, 0), 0) AS NUM_FACTURA,
    COALESCE(TRY_TO_TIMESTAMP_NTZ(NULLIF(TRIM(raw."MOM_SIT_FACT"), '')), '0001-01-01 00:00:00.000'::TIMESTAMP_NTZ) AS MOM_SIT_FACT,
    COALESCE(NULLIF(TRIM(raw."TIP_SIT_FACT"), ''), '^^') AS TIP_SIT_FACT,
    COALESCE(NULLIF(TRIM(raw."CAUSA_SIT_FACT"), ''), '^^') AS CAUSA_SIT_FACT,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_SITUACIO_FACT' AS TABLA_ORIGEN
from raw
