{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'link']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(c.NUM_MUN_SGAB)) AS NUM_MUN_SGAB,
        TO_VARCHAR(c.NUM_CARRER) AS NUM_CARRER,

        c.ID_CARGA,
        c.FECHA_EXTRACCION,
        c.SISTEMA_ORIGEN

    FROM {{ ref('l4_carrer') }} AS c

    WHERE NULLIF(TRIM(c.NUM_MUN_SGAB), '') IS NOT NULL
    AND c.NUM_CARRER IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS(
                '|',
                NUM_MUN_SGAB,
                NUM_CARRER
            ),
            256
        ) AS HK_MUNICIPI_CARRER,

        SHA2_HEX(
            NUM_MUN_SGAB,
            256
        ) AS HK_MUNICIPI_SGAB,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                NUM_MUN_SGAB,
                NUM_CARRER
            ),
            256
        ) AS HK_CARRER,

        NUM_MUN_SGAB,
        NUM_CARRER,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT
    src.HK_MUNICIPI_CARRER,
    src.HK_MUNICIPI_SGAB,
    src.HK_CARRER,

    src.NUM_MUN_SGAB,
    src.NUM_CARRER,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_CARRER' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1

    FROM {{ this }} AS target

    WHERE target.HK_MUNICIPI_CARRER =
          src.HK_MUNICIPI_CARRER

)

{% endif %}