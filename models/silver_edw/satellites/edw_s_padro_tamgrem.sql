{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        TS_PADRO_TAMGREM,

        TIP_TAXA_TAMGREM,
        NOMB_HABIT_SUBM,
        CONSUM_MES_BASE,
        TIP_QUOTA_TAMGREM,
        CONSUM_MIG_DIA,
        NUMERO_EMPLEAT,
        PERC_BONIF_TAMGREM,
        IMP_CUOTA,
        SUPERFICIE_REAL,
        SUPERFICIE_POND,
        NIV_GEN_RES,
        COD_GEN_RES,
        ORIGEN,
        ID_BONIF_DECGER,
        ID_LIMIT,
        SUBTIP_TAXA_TAMGREM,
        OBSERVACIONS,
        TS_ALTA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_padro_tamgrem') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL
      AND TS_PADRO_TAMGREM IS NOT NULL

),

hashed_source AS (

    SELECT

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
                COALESCE(NULLIF(TRIM(TIP_TAXA_TAMGREM), ''), '^^'),
                COALESCE(TO_VARCHAR(NOMB_HABIT_SUBM), '^^'),
                COALESCE(TO_VARCHAR(CONSUM_MES_BASE), '^^'),
                COALESCE(NULLIF(TRIM(TIP_QUOTA_TAMGREM), ''), '^^'),
                COALESCE(TO_VARCHAR(CONSUM_MIG_DIA, 'FM999999999999990.0000'), '^^'),
                COALESCE(NULLIF(TRIM(NUMERO_EMPLEAT), ''), '^^'),
                COALESCE(TO_VARCHAR(PERC_BONIF_TAMGREM, 'FM999999999999990.0000'), '^^'),
                COALESCE(TO_VARCHAR(IMP_CUOTA, 'FM999999999999990.0000'), '^^'),
                COALESCE(TO_VARCHAR(SUPERFICIE_REAL), '^^'),
                COALESCE(TO_VARCHAR(SUPERFICIE_POND, 'FM999999999999990.0000'), '^^'),
                COALESCE(NULLIF(TRIM(NIV_GEN_RES), ''), '^^'),
                COALESCE(NULLIF(TRIM(COD_GEN_RES), ''), '^^'),
                COALESCE(NULLIF(TRIM(ORIGEN), ''), '^^'),
                COALESCE(NULLIF(TRIM(ID_BONIF_DECGER), ''), '^^'),
                COALESCE(NULLIF(TRIM(ID_LIMIT), ''), '^^'),
                COALESCE(NULLIF(TRIM(SUBTIP_TAXA_TAMGREM), ''), '^^'),
                COALESCE(NULLIF(TRIM(OBSERVACIONS), ''), '^^'),
                COALESCE(TO_VARCHAR(TS_ALTA, 'YYYY-MM-DD HH24:MI:SS.FF9'), '^^')
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
        HK_PADRO_TAMGREM,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_PADRO_TAMGREM
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

    'L4_PADRO_TAMGREM' AS TABLA_ORIGEN

FROM hashed_source src

{% if is_incremental() %}

LEFT JOIN latest_target target
    ON target.HK_PADRO_TAMGREM = src.HK_PADRO_TAMGREM

WHERE target.HK_PADRO_TAMGREM IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}