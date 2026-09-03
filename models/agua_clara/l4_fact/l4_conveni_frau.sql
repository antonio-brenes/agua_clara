{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_conveni_frau') }}
)

select
    NULLIF(TRIM(raw."POLISSA_SUBM"), '') AS POLISSA_SUBM,
    NULLIF(TRIM(raw."NUM_MUN_CONV_FRAU"), '') AS NUM_MUN_CONV_FRAU,
    NULLIF(TRIM(raw."ADRE_CONV_FRAU"), '') AS ADRE_CONV_FRAU,
    NULLIF(TRIM(raw."COD_POST_CONV_FRAU"), '') AS COD_POST_CONV_FRAU,
    NULLIF(TRIM(raw."DEL_CREACIO_CONV_F"), '') AS DEL_CREACIO_CONV_F,
    TRY_TO_DATE(NULLIF(TRIM(raw."DATA_CREA_C_FRA"), '')) AS DATA_CREA_C_FRA,
    NULLIF(TRIM(raw."POLISSA_RAMAL"), '') AS POLISSA_RAMAL,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_CONVENI_FRAU' AS TABLA_ORIGEN
from raw
