{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(c.NUM_MUN_SGAB)) AS NUM_MUN_SGAB,
        TO_VARCHAR(c.NUM_CARRER) AS NUM_CARRER,

        c.CLASSE_CARRER,
        c.NOM_ABREUJ_CARRER,
        c.TIP_DENOMIN_CARRER,
        c.NOM_COMPLET_CARRER,
        c.ID_CARRER_SAP,
        c.QL_CARRER,

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
        ) AS HK_CARRER,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(UPPER(TRIM(CLASSE_CARRER)), '^^'),
                COALESCE(UPPER(TRIM(NOM_ABREUJ_CARRER)), '^^'),
                COALESCE(UPPER(TRIM(TIP_DENOMIN_CARRER)), '^^'),
                COALESCE(UPPER(TRIM(NOM_COMPLET_CARRER)), '^^'),
                COALESCE(UPPER(TRIM(ID_CARRER_SAP)), '^^'),
                COALESCE(UPPER(TRIM(QL_CARRER)), '^^')
            ),
            256
        ) AS HASHDIFF,

        NUM_MUN_SGAB,
        NUM_CARRER,

        CLASSE_CARRER,
        NOM_ABREUJ_CARRER,
        TIP_DENOMIN_CARRER,
        NOM_COMPLET_CARRER,
        ID_CARRER_SAP,
        QL_CARRER,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_CARRER,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_CARRER
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT
    src.HK_CARRER,
    src.HASHDIFF,

    src.NUM_MUN_SGAB,
    src.NUM_CARRER,

    src.CLASSE_CARRER,
    src.NOM_ABREUJ_CARRER,
    src.TIP_DENOMIN_CARRER,
    src.NOM_COMPLET_CARRER,
    src.ID_CARRER_SAP,
    src.QL_CARRER,

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

LEFT JOIN latest_target AS target
    ON target.HK_CARRER = src.HK_CARRER

WHERE target.HK_CARRER IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}