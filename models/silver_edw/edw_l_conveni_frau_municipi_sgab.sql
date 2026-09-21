{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'link']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        UPPER(TRIM(NUM_MUN_CONV_FRAU)) AS NUM_MUN_SGAB,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_conveni_frau') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL
      AND NULLIF(TRIM(NUM_MUN_CONV_FRAU), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            CONCAT_WS(
                '|',
                POLISSA_SUBM,
                NUM_MUN_SGAB
            ),
            256
        ) AS HK_CONVENI_FRAU_MUNICIPI_SGAB,

        SHA2_HEX(
            POLISSA_SUBM,
            256
        ) AS HK_CONVENI_FRAU,

        SHA2_HEX(
            NUM_MUN_SGAB,
            256
        ) AS HK_MUNICIPI_SGAB,

        POLISSA_SUBM,
        NUM_MUN_SGAB,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT

    src.HK_CONVENI_FRAU_MUNICIPI_SGAB,
    src.HK_CONVENI_FRAU,
    src.HK_MUNICIPI_SGAB,

    src.POLISSA_SUBM,
    src.NUM_MUN_SGAB,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_CONVENI_FRAU' AS TABLA_ORIGEN

FROM hashed_source src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} tgt
    WHERE tgt.HK_CONVENI_FRAU_MUNICIPI_SGAB =
          src.HK_CONVENI_FRAU_MUNICIPI_SGAB

)

{% endif %}