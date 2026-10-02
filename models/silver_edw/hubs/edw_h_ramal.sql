{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'hub']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(POLISSA_RAMAL)) AS POLISSA_RAMAL,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN,

        CONVERT_TIMEZONE(
            'Europe/Madrid',
            CURRENT_TIMESTAMP()
        ) AS FECHA_CARGA

    FROM {{ ref('l4_ramal') }}

    WHERE NULLIF(TRIM(POLISSA_RAMAL), '') IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            POLISSA_RAMAL,
            256
        ) AS HK_RAMAL,

        POLISSA_RAMAL,

        ID_CARGA,
        FECHA_EXTRACCION,
        FECHA_CARGA,
        SISTEMA_ORIGEN,

        'L4_RAMAL' AS TABLA_ORIGEN

    FROM source_data

)

SELECT
    src.HK_RAMAL,
    src.POLISSA_RAMAL,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,
    src.FECHA_CARGA,
    src.SISTEMA_ORIGEN,
    src.TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} AS tgt

    WHERE tgt.HK_RAMAL = src.HK_RAMAL

)

{% endif %}