{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['POLISSA_SUBM', 'TS_PADRO_TRR'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_padro_trr') }}
)

select
    COALESCE(NULLIF(TRIM(raw."POLISSA_SUBM"), ''), '^^') AS POLISSA_SUBM,
    COALESCE(TRY_TO_TIMESTAMP_NTZ(NULLIF(TRIM(raw."TS_PADRO_TRR"), '')), '0001-01-01 00:00:00.000'::TIMESTAMP_NTZ) AS TS_PADRO_TRR,
    COALESCE(NULLIF(TRIM(raw."TIP_TAXA_TRR"), ''), '^^') AS TIP_TAXA_TRR,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NOMB_HABIT_SUBM"), ''), 3, 0), 0) AS NOMB_HABIT_SUBM,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."CONSUM_MES_BASE"), ''), 7, 2), 0) AS CONSUM_MES_BASE,
    COALESCE(NULLIF(TRIM(raw."TIP_QUOTA_TRR"), ''), '^^') AS TIP_QUOTA_TRR,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."CONSUM_MIG_DIA"), ''), 9, 4), 0) AS CONSUM_MIG_DIA,
    COALESCE(NULLIF(TRIM(raw."NUMERO_EMPLEAT"), ''), '^^') AS NUMERO_EMPLEAT,
    COALESCE(NULLIF(TRIM(raw."SECCIO"), ''), '^^') AS SECCIO,
    COALESCE(NULLIF(TRIM(raw."EPIGRAF_IAE"), ''), '^^') AS EPIGRAF_IAE,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."PERC_BONIF_TRR"), ''), 5, 2), 0) AS PERC_BONIF_TRR,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_PADRO_TRR' AS TABLA_ORIGEN
from raw
