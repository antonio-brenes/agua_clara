{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'hub']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_servei_eq_ci') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            POLISSA_SUBM,
            256
        ) AS HK_SERVEI_EQ_CI,

        POLISSA_SUBM,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT

    src.HK_SERVEI_EQ_CI,
    src.POLISSA_SUBM,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_SERVEI_EQ_CI' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} tgt
    WHERE tgt.HK_SERVEI_EQ_CI = src.HK_SERVEI_EQ_CI

)

{% endif %}