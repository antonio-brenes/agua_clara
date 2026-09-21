{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(SECCIO)) AS SECCIO,
        UPPER(TRIM(EPIGRAF_IAE)) AS EPIGRAF_IAE,

        DESCR_IAE,
        TIP_TARIFA,
        TIP_QUOTA_TAMGREM,
        NIV_GEN_RES,
        COD_GEN_RES,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_epigraf_iae') }}

    WHERE NULLIF(TRIM(SECCIO), '') IS NOT NULL
      AND NULLIF(TRIM(EPIGRAF_IAE), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            CONCAT_WS('|', SECCIO, EPIGRAF_IAE),
            256
        ) AS HK_EPIGRAF_IAE,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(NULLIF(TRIM(DESCR_IAE), ''), '^^'),
                COALESCE(NULLIF(TRIM(TIP_TARIFA), ''), '^^'),
                COALESCE(NULLIF(TRIM(TIP_QUOTA_TAMGREM), ''), '^^'),
                COALESCE(NULLIF(TRIM(NIV_GEN_RES), ''), '^^'),
                COALESCE(NULLIF(TRIM(COD_GEN_RES), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        SECCIO,
        EPIGRAF_IAE,

        DESCR_IAE,
        TIP_TARIFA,
        TIP_QUOTA_TAMGREM,
        NIV_GEN_RES,
        COD_GEN_RES,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_EPIGRAF_IAE,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_EPIGRAF_IAE
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_EPIGRAF_IAE,
    src.HASHDIFF,

    src.SECCIO,
    src.EPIGRAF_IAE,

    src.DESCR_IAE,
    src.TIP_TARIFA,
    src.TIP_QUOTA_TAMGREM,
    src.NIV_GEN_RES,
    src.COD_GEN_RES,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_EPIGRAF_IAE' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_EPIGRAF_IAE =
       src.HK_EPIGRAF_IAE

WHERE target.HK_EPIGRAF_IAE IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}