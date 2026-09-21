{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(CLAU_CODI)) AS COD_TIPO_USO_AGUA,

        DESC_CODI AS DES_TIPO_USO_AGUA,
        DESC_BREU AS DES_ABREV_TIPO_USO_AGUA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_codificacions') }}

    WHERE TIP_CODI = 'US'
      AND NULLIF(TRIM(CLAU_CODI), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            COD_TIPO_USO_AGUA,
            256
        ) AS HK_TIPO_USO_AGUA,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(NULLIF(TRIM(DES_TIPO_USO_AGUA), ''), '^^'),
                COALESCE(NULLIF(TRIM(DES_ABREV_TIPO_USO_AGUA), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        COD_TIPO_USO_AGUA,

        DES_TIPO_USO_AGUA,
        DES_ABREV_TIPO_USO_AGUA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_TIPO_USO_AGUA,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_TIPO_USO_AGUA
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_TIPO_USO_AGUA,
    src.HASHDIFF,

    src.COD_TIPO_USO_AGUA,

    src.DES_TIPO_USO_AGUA,
    src.DES_ABREV_TIPO_USO_AGUA,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_CODIFICACIONS [TIP_CODI=''US'']' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_TIPO_USO_AGUA =
       src.HK_TIPO_USO_AGUA

WHERE target.HK_TIPO_USO_AGUA IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}