{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,

        NOMB_BOQUES_25,
        NOMB_BOQUES_45,
        NOMB_BOQUES_70,
        NOMB_BOQUES_100,
        NOMB_SPRINCKLERS,
        NUM_PRECINTE_BOCA,
        ID_GRUP_ELEV_EQ_CI,
        ID_VALVULA_MOTOR,
        TIP_PETIC_RES,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_servei_eq_ci') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            POLISSA_SUBM,
            256
        ) AS HK_SERVEI_EQ_CI,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(TO_VARCHAR(NOMB_BOQUES_25), '^^'),
                COALESCE(TO_VARCHAR(NOMB_BOQUES_45), '^^'),
                COALESCE(TO_VARCHAR(NOMB_BOQUES_70), '^^'),
                COALESCE(TO_VARCHAR(NOMB_BOQUES_100), '^^'),
                COALESCE(TO_VARCHAR(NOMB_SPRINCKLERS), '^^'),
                COALESCE(NULLIF(TRIM(NUM_PRECINTE_BOCA), ''), '^^'),
                COALESCE(NULLIF(TRIM(ID_GRUP_ELEV_EQ_CI), ''), '^^'),
                COALESCE(NULLIF(TRIM(ID_VALVULA_MOTOR), ''), '^^'),
                COALESCE(NULLIF(TRIM(TIP_PETIC_RES), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        POLISSA_SUBM,

        NOMB_BOQUES_25,
        NOMB_BOQUES_45,
        NOMB_BOQUES_70,
        NOMB_BOQUES_100,
        NOMB_SPRINCKLERS,
        NUM_PRECINTE_BOCA,
        ID_GRUP_ELEV_EQ_CI,
        ID_VALVULA_MOTOR,
        TIP_PETIC_RES,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_SERVEI_EQ_CI,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_SERVEI_EQ_CI
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_SERVEI_EQ_CI,
    src.HASHDIFF,

    src.POLISSA_SUBM,

    src.NOMB_BOQUES_25,
    src.NOMB_BOQUES_45,
    src.NOMB_BOQUES_70,
    src.NOMB_BOQUES_100,
    src.NOMB_SPRINCKLERS,
    src.NUM_PRECINTE_BOCA,
    src.ID_GRUP_ELEV_EQ_CI,
    src.ID_VALVULA_MOTOR,
    src.TIP_PETIC_RES,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_SERVEI_EQ_CI' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_SERVEI_EQ_CI =
       src.HK_SERVEI_EQ_CI

WHERE target.HK_SERVEI_EQ_CI IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}