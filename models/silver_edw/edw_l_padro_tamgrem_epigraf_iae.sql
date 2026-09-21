{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'link']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        TS_PADRO_TAMGREM,

        UPPER(TRIM(SECCIO)) AS SECCIO,
        UPPER(TRIM(EPIGRAF_IAE)) AS EPIGRAF_IAE,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_padro_tamgrem') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL
      AND TS_PADRO_TAMGREM IS NOT NULL
      AND NULLIF(TRIM(SECCIO), '') IS NOT NULL
      AND NULLIF(TRIM(EPIGRAF_IAE), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            CONCAT_WS(
                '|',
                POLISSA_SUBM,
                TO_VARCHAR(TS_PADRO_TAMGREM, 'YYYY-MM-DD HH24:MI:SS.FF9'),
                SECCIO,
                EPIGRAF_IAE
            ),
            256
        ) AS HK_PADRO_TAMGREM_EPIGRAF_IAE,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                POLISSA_SUBM,
                TO_VARCHAR(TS_PADRO_TAMGREM, 'YYYY-MM-DD HH24:MI:SS.FF9')
            ),
            256
        ) AS HK_PADRO_TAMGREM,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                SECCIO,
                EPIGRAF_IAE
            ),
            256
        ) AS HK_EPIGRAF_IAE,

        POLISSA_SUBM,
        TS_PADRO_TAMGREM,
        SECCIO,
        EPIGRAF_IAE,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT

    src.HK_PADRO_TAMGREM_EPIGRAF_IAE,
    src.HK_PADRO_TAMGREM,
    src.HK_EPIGRAF_IAE,

    src.POLISSA_SUBM,
    src.TS_PADRO_TAMGREM,
    src.SECCIO,
    src.EPIGRAF_IAE,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_PADRO_TAMGREM' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} tgt
    WHERE tgt.HK_PADRO_TAMGREM_EPIGRAF_IAE =
          src.HK_PADRO_TAMGREM_EPIGRAF_IAE

)

{% endif %}