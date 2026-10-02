{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'hub']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(NUM_MUN_SGAB)) AS NUM_MUN_SGAB,
        UPPER(TRIM(NUM_DTE_MUNI)) AS NUM_DTE_MUNI,
        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN
    FROM {{ ref('l4_dte_municipal') }}
    WHERE NULLIF(TRIM(NUM_MUN_SGAB), '') IS NOT NULL
      AND NULLIF(TRIM(NUM_DTE_MUNI), '') IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS('|', NUM_MUN_SGAB, NUM_DTE_MUNI),
            256
        ) AS HK_DTE_MUNICIPAL,

        NUM_MUN_SGAB,
        NUM_DTE_MUNI,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT
    src.HK_DTE_MUNICIPAL,

    src.NUM_MUN_SGAB,
    src.NUM_DTE_MUNI,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_DTE_MUNICIPAL' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} tgt
    WHERE tgt.HK_DTE_MUNICIPAL = src.HK_DTE_MUNICIPAL

)

{% endif %}