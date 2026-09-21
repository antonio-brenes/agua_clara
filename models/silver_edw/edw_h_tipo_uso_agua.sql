{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'hub']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(CLAU_CODI)) AS COD_TIPO_USO_AGUA,
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

        COD_TIPO_USO_AGUA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT

    src.HK_TIPO_USO_AGUA,
    src.COD_TIPO_USO_AGUA,

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

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} tgt
    WHERE tgt.HK_TIPO_USO_AGUA = src.HK_TIPO_USO_AGUA

)

{% endif %}