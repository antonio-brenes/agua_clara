{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(NUM_MUN_SGAB)) AS NUM_MUN_SGAB,
        UPPER(TRIM(NUM_DTE_MUNI)) AS NUM_DTE_MUNI,

        NOM_DTE_MUNI,
        NUM_DEL_SGAB,
        NUM_AGENCIA_SGAB,
        CODI_AREA_SD,

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

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(NULLIF(TRIM(NOM_DTE_MUNI), ''), '^^'),
                COALESCE(TO_VARCHAR(NUM_DEL_SGAB), '^^'),
                COALESCE(TO_VARCHAR(NUM_AGENCIA_SGAB), '^^'),
                COALESCE(NULLIF(TRIM(CODI_AREA_SD), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        NUM_MUN_SGAB,
        NUM_DTE_MUNI,
        NOM_DTE_MUNI,
        NUM_DEL_SGAB,
        NUM_AGENCIA_SGAB,
        CODI_AREA_SD,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_DTE_MUNICIPAL,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_DTE_MUNICIPAL
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_DTE_MUNICIPAL,
    src.HASHDIFF,

    src.NUM_MUN_SGAB,
    src.NUM_DTE_MUNI,
    src.NOM_DTE_MUNI,
    src.NUM_DEL_SGAB,
    src.NUM_AGENCIA_SGAB,
    src.CODI_AREA_SD,

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

LEFT JOIN latest_target AS target
    ON target.HK_DTE_MUNICIPAL =
       src.HK_DTE_MUNICIPAL

WHERE target.HK_DTE_MUNICIPAL IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}