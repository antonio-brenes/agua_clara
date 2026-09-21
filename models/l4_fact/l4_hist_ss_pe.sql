{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['POLISSA_SUBM', 'TIP_COLECTIVO', 'TS_MOM_IND'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_hist_ss_pe') }}
)

select
    COALESCE(NULLIF(TRIM(raw."POLISSA_SUBM"), ''), '^^') AS POLISSA_SUBM,
    COALESCE(TRY_TO_TIMESTAMP_NTZ(NULLIF(TRIM(raw."TS_MOM_IND"), '')), '0001-01-01 00:00:00.000'::TIMESTAMP_NTZ) AS TS_MOM_IND,
    COALESCE(NULLIF(TRIM(raw."TIP_COLECTIVO"), ''), '^^') AS TIP_COLECTIVO,
    COALESCE(TRY_TO_DATE(NULLIF(TRIM(raw."DATA_INI_IND"), '')), '0001-01-01'::DATE) AS DATA_INI_IND,
    COALESCE(TRY_TO_DATE(NULLIF(TRIM(raw."DATA_FIN_IND"), '')), '0001-01-01'::DATE) AS DATA_FIN_IND,
    COALESCE(NULLIF(TRIM(raw."OBSERVACIONS"), ''), '^^') AS OBSERVACIONS,
    COALESCE(NULLIF(TRIM(raw."NUM_EMPLEAT"), ''), '^^') AS NUM_EMPLEAT,
    COALESCE(NULLIF(TRIM(raw."INFORME_SS"), ''), '^^') AS INFORME_SS,
    COALESCE(TRY_TO_DATE(NULLIF(TRIM(raw."DATA_ENVIA_ACA"), '')), '0001-01-01'::DATE) AS DATA_ENVIA_ACA,
    COALESCE(NULLIF(TRIM(raw."NOM_ACA_FITXER"), ''), '^^') AS NOM_ACA_FITXER,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_HIST_SS_PE' AS TABLA_ORIGEN
from raw
