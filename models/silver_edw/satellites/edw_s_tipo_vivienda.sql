{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(CLAU_CODI)) AS COD_TIPO_VIVIENDA,

        DESC_CODI AS DES_TIPO_VIVIENDA,
        DESC_BREU AS DES_ABREV_TIPO_VIVIENDA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_codificacions') }}

    WHERE TIP_CODI = 'THL'
      AND NULLIF(TRIM(CLAU_CODI), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            COD_TIPO_VIVIENDA,
            256
        ) AS HK_TIPO_VIVIENDA,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(NULLIF(TRIM(DES_TIPO_VIVIENDA), ''), '^^'),
                COALESCE(NULLIF(TRIM(DES_ABREV_TIPO_VIVIENDA), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        COD_TIPO_VIVIENDA,

        DES_TIPO_VIVIENDA,
        DES_ABREV_TIPO_VIVIENDA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_TIPO_VIVIENDA,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_TIPO_VIVIENDA
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_TIPO_VIVIENDA,
    src.HASHDIFF,

    src.COD_TIPO_VIVIENDA,

    src.DES_TIPO_VIVIENDA,
    src.DES_ABREV_TIPO_VIVIENDA,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_CODIFICACIONS [TIP_CODI=''THL'']' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_TIPO_VIVIENDA =
       src.HK_TIPO_VIVIENDA

WHERE target.HK_TIPO_VIVIENDA IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}