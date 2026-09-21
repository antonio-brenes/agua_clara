{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['POLISSA_SUBM'],
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_servei_eq_ci') }}
)

select
    COALESCE(NULLIF(TRIM(raw."POLISSA_SUBM"), ''), '^^') AS POLISSA_SUBM,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NOMB_BOQUES_25"), ''), 3, 0), 0) AS NOMB_BOQUES_25,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NOMB_BOQUES_45"), ''), 3, 0), 0) AS NOMB_BOQUES_45,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NOMB_BOQUES_70"), ''), 3, 0), 0) AS NOMB_BOQUES_70,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NOMB_BOQUES_100"), ''), 3, 0), 0) AS NOMB_BOQUES_100,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NOMB_SPRINCKLERS"), ''), 5, 0), 0) AS NOMB_SPRINCKLERS,
    COALESCE(TRY_TO_DECIMAL(NULLIF(TRIM(raw."NUM_PRECINTE_BOCA"), ''), 3, 0), 0) AS NUM_PRECINTE_BOCA,
    COALESCE(NULLIF(TRIM(raw."ID_GRUP_ELEV_EQ_CI"), ''), '^^') AS ID_GRUP_ELEV_EQ_CI,
    COALESCE(NULLIF(TRIM(raw."ID_VALVULA_MOTOR"), ''), '^^') AS ID_VALVULA_MOTOR,
    COALESCE(NULLIF(TRIM(raw."TIP_PETIC_RES"), ''), '^^') AS TIP_PETIC_RES,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_SERVEI_EQ_CI' AS TABLA_ORIGEN
from raw
