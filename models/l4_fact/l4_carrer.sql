{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['NUM_MUN_SGAB', 'NUM_CARRER'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_carrer') }}
)

select
    COALESCE(NULLIF(TRIM(raw."NUM_MUN_SGAB"), ''), '^^') AS NUM_MUN_SGAB,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NUM_CARRER"), ''), 6, 0), 0) AS NUM_CARRER,
    COALESCE(NULLIF(TRIM(raw."CLASSE_CARRER"), ''), '^^') AS CLASSE_CARRER,
    COALESCE(NULLIF(TRIM(raw."NOM_ABREUJ_CARRER"), ''), '^^') AS NOM_ABREUJ_CARRER,
    COALESCE(NULLIF(TRIM(raw."TIP_DENOMIN_CARRER"), ''), '^^') AS TIP_DENOMIN_CARRER,
    COALESCE(NULLIF(TRIM(raw."NOM_COMPLET_CARRER"), ''), '^^') AS NOM_COMPLET_CARRER,
    COALESCE(NULLIF(TRIM(raw."ID_CARRER_SAP"), ''), '^^') AS ID_CARRER_SAP,
    COALESCE(NULLIF(TRIM(raw."QL_CARRER"), ''), '^^') AS QL_CARRER,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_CARRER' AS TABLA_ORIGEN
from raw
