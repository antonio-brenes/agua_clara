{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,

        ADRE_CONV_FRAU,
        COD_POST_CONV_FRAU,
        DEL_CREACIO_CONV_F,
        DATA_CREA_C_FRA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_conveni_frau') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            POLISSA_SUBM,
            256
        ) AS HK_CONVENI_FRAU,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(NULLIF(TRIM(ADRE_CONV_FRAU), ''), '^^'),
                COALESCE(NULLIF(TRIM(COD_POST_CONV_FRAU), ''), '^^'),
                COALESCE(NULLIF(TRIM(DEL_CREACIO_CONV_F), ''), '^^'),
                COALESCE(TO_VARCHAR(DATA_CREA_C_FRA, 'YYYY-MM-DD'), '^^')
            ),
            256
        ) AS HASHDIFF,

        POLISSA_SUBM,

        ADRE_CONV_FRAU,
        COD_POST_CONV_FRAU,
        DEL_CREACIO_CONV_F,
        DATA_CREA_C_FRA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_CONVENI_FRAU,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_CONVENI_FRAU
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_CONVENI_FRAU,
    src.HASHDIFF,

    src.POLISSA_SUBM,

    src.ADRE_CONV_FRAU,
    src.COD_POST_CONV_FRAU,
    src.DEL_CREACIO_CONV_F,
    src.DATA_CREA_C_FRA,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_CONVENI_FRAU' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_CONVENI_FRAU =
       src.HK_CONVENI_FRAU

WHERE target.HK_CONVENI_FRAU IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}