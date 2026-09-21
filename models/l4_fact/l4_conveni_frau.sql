{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['POLISSA_SUBM'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_conveni_frau') }}
)

select
    COALESCE(NULLIF(TRIM(raw."POLISSA_SUBM"), ''), '^^') AS POLISSA_SUBM,
    COALESCE(NULLIF(TRIM(raw."NUM_MUN_CONV_FRAU"), ''), '^^') AS NUM_MUN_CONV_FRAU,
    COALESCE(NULLIF(TRIM(raw."ADRE_CONV_FRAU"), ''), '^^') AS ADRE_CONV_FRAU,
    COALESCE(NULLIF(TRIM(raw."COD_POST_CONV_FRAU"), ''), '^^') AS COD_POST_CONV_FRAU,
    COALESCE(NULLIF(TRIM(raw."DEL_CREACIO_CONV_F"), ''), '^^') AS DEL_CREACIO_CONV_F,
    COALESCE(TRY_TO_DATE(NULLIF(TRIM(raw."DATA_CREA_C_FRA"), '')), '0001-01-01'::DATE) AS DATA_CREA_C_FRA,
    COALESCE(NULLIF(TRIM(raw."POLISSA_RAMAL"), ''), '^^') AS POLISSA_RAMAL,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_CONVENI_FRAU' AS TABLA_ORIGEN
from raw
