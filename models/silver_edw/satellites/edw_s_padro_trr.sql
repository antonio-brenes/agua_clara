{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        TS_PADRO_TRR,

        TIP_TAXA_TRR,
        NOMB_HABIT_SUBM,
        CONSUM_MES_BASE,
        TIP_QUOTA_TRR,
        CONSUM_MIG_DIA,
        NUMERO_EMPLEAT,
        PERC_BONIF_TRR,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_padro_trr') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL
      AND TS_PADRO_TRR IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            CONCAT_WS(
                '|',
                POLISSA_SUBM,
                TO_VARCHAR(TS_PADRO_TRR, 'YYYY-MM-DD HH24:MI:SS.FF9')
            ),
            256
        ) AS HK_PADRO_TRR,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(NULLIF(TRIM(TIP_TAXA_TRR), ''), '^^'),
                COALESCE(TO_VARCHAR(NOMB_HABIT_SUBM), '^^'),
                COALESCE(TO_VARCHAR(CONSUM_MES_BASE, 'FM999999999999990.0000'), '^^'),
                COALESCE(NULLIF(TRIM(TIP_QUOTA_TRR), ''), '^^'),
                COALESCE(TO_VARCHAR(CONSUM_MIG_DIA, 'FM999999999999990.0000'), '^^'),
                COALESCE(NULLIF(TRIM(NUMERO_EMPLEAT), ''), '^^'),
                COALESCE(TO_VARCHAR(PERC_BONIF_TRR, 'FM999999999999990.0000'), '^^')
            ),
            256
        ) AS HASHDIFF,

        *

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_PADRO_TRR,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_PADRO_TRR
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.*,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    'L4_PADRO_TRR' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_PADRO_TRR = src.HK_PADRO_TRR

WHERE target.HK_PADRO_TRR IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}