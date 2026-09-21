{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['TIP_TARIFA', 'SUBTIP_TARIFA', 'DATA_INI_VIGENCIA'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_tarifa_facturacio') }}
)

select
    COALESCE(NULLIF(TRIM(raw."TIP_TARIFA"), ''), '^^') AS TIP_TARIFA,
    COALESCE(NULLIF(TRIM(raw."SUBTIP_TARIFA"), ''), '^^') AS SUBTIP_TARIFA,
    COALESCE(TRY_TO_DATE(NULLIF(TRIM(raw."DATA_INI_VIGENCIA"), '')), '0001-01-01'::DATE) AS DATA_INI_VIGENCIA,
    TRY_TO_DATE(NULLIF(TRIM(raw."DATA_FI_VIGENCIA"), '')) AS DATA_FI_VIGENCIA,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."ORDRE"), ''), 3, 0), 0) AS ORDRE,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."VALOR_NUMERIC"), ''), 18, 6), 0) AS VALOR_NUMERIC,
    COALESCE(NULLIF(TRIM(raw."UNITAT"), ''), '^^') AS UNITAT,
    NULLIF(TRIM(raw."OBSERVACIONS"), '') AS OBSERVACIONS,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_TARIFA_FACTURACIO' AS TABLA_ORIGEN
from raw
