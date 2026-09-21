{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'hub']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(m.NUM_MUN_SGAB)) AS NUM_MUN_SGAB,

        m.ID_CARGA,
        m.FECHA_EXTRACCION,
        m.SISTEMA_ORIGEN

    FROM {{ ref('l4_municipi_sgab') }} AS m

    WHERE NULLIF(TRIM(m.NUM_MUN_SGAB), '') IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            NUM_MUN_SGAB,
            256
        ) AS HK_MUNICIPI_SGAB,

        NUM_MUN_SGAB,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT
    src.HK_MUNICIPI_SGAB,
    src.NUM_MUN_SGAB,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_MUNICIPI_SGAB' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1

    FROM {{ this }} AS target

    WHERE target.HK_MUNICIPI_SGAB =
          src.HK_MUNICIPI_SGAB

)

{% endif %}