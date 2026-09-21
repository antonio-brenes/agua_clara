{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'link']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        UPPER(TRIM(SECCIO)) AS SECCIO,
        UPPER(TRIM(EPIGRAF_IAE)) AS EPIGRAF_IAE,
        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_submin_iae') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL
      AND NULLIF(TRIM(SECCIO), '') IS NOT NULL
      AND NULLIF(TRIM(EPIGRAF_IAE), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            CONCAT_WS(
                '|',
                POLISSA_SUBM,
                SECCIO,
                EPIGRAF_IAE
            ),
            256
        ) AS HK_SUBMIN_IAE,

        SHA2_HEX(
            POLISSA_SUBM,
            256
        ) AS HK_SUBMIN_SERVEI,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                SECCIO,
                EPIGRAF_IAE
            ),
            256
        ) AS HK_EPIGRAF_IAE,

        POLISSA_SUBM,
        SECCIO,
        EPIGRAF_IAE,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT

    src.HK_SUBMIN_IAE,
    src.HK_SUBMIN_SERVEI,
    src.HK_EPIGRAF_IAE,

    src.POLISSA_SUBM,
    src.SECCIO,
    src.EPIGRAF_IAE,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_SUBMIN_IAE' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} tgt
    WHERE tgt.HK_SUBMIN_IAE = src.HK_SUBMIN_IAE

)

{% endif %}