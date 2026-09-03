{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from {{ source('raw_sicab', 'raw_carrer') }}
)

select
    NULLIF(TRIM(raw."NUM_MUN_SGAB"), '') AS NUM_MUN_SGAB,
    TRY_TO_DECIMAL(NULLIF(TRIM(raw."NUM_CARRER"), ''), 6, 0) AS NUM_CARRER,
    NULLIF(TRIM(raw."CLASSE_CARRER"), '') AS CLASSE_CARRER,
    NULLIF(TRIM(raw."NOM_ABREUJ_CARRER"), '') AS NOM_ABREUJ_CARRER,
    NULLIF(TRIM(raw."TIP_DENOMIN_CARRER"), '') AS TIP_DENOMIN_CARRER,
    NULLIF(TRIM(raw."NOM_COMPLET_CARRER"), '') AS NOM_COMPLET_CARRER,
    NULLIF(TRIM(raw."ID_CARRER_SAP"), '') AS ID_CARRER_SAP,
    NULLIF(TRIM(raw."QL_CARRER"), '') AS QL_CARRER,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    raw.FECHA_EXTRACCION AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    raw.SISTEMA_ORIGEN AS SISTEMA_ORIGEN,
    'RAW_CARRER' AS TABLA_ORIGEN
from raw
