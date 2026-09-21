{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        UPPER(TRIM(TIP_COLECTIVO)) AS TIP_COLECTIVO,
        TS_MOM_IND,

        DATA_INI_IND,
        DATA_FIN_IND,
        OBSERVACIONS,
        NUM_EMPLEAT,
        INFORME_SS,
        DATA_ENVIA_ACA,
        NOM_ACA_FITXER,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_hist_ss_pe') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL
      AND NULLIF(TRIM(TIP_COLECTIVO), '') IS NOT NULL
      AND TS_MOM_IND IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            CONCAT_WS(
                '|',
                POLISSA_SUBM,
                TIP_COLECTIVO,
                TO_VARCHAR(TS_MOM_IND, 'YYYY-MM-DD HH24:MI:SS.FF9')
            ),
            256
        ) AS HK_HIST_SS_PE,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(TO_VARCHAR(DATA_INI_IND, 'YYYY-MM-DD'), '^^'),
                COALESCE(TO_VARCHAR(DATA_FIN_IND, 'YYYY-MM-DD'), '^^'),
                COALESCE(NULLIF(TRIM(OBSERVACIONS), ''), '^^'),
                COALESCE(NULLIF(TRIM(NUM_EMPLEAT), ''), '^^'),
                COALESCE(NULLIF(TRIM(INFORME_SS), ''), '^^'),
                COALESCE(TO_VARCHAR(DATA_ENVIA_ACA, 'YYYY-MM-DD'), '^^'),
                COALESCE(NULLIF(TRIM(NOM_ACA_FITXER), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        POLISSA_SUBM,
        TIP_COLECTIVO,
        TS_MOM_IND,

        DATA_INI_IND,
        DATA_FIN_IND,
        OBSERVACIONS,
        NUM_EMPLEAT,
        INFORME_SS,
        DATA_ENVIA_ACA,
        NOM_ACA_FITXER,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_HIST_SS_PE,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_HIST_SS_PE
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_HIST_SS_PE,
    src.HASHDIFF,

    src.POLISSA_SUBM,
    src.TIP_COLECTIVO,
    src.TS_MOM_IND,

    src.DATA_INI_IND,
    src.DATA_FIN_IND,
    src.OBSERVACIONS,
    src.NUM_EMPLEAT,
    src.INFORME_SS,
    src.DATA_ENVIA_ACA,
    src.NOM_ACA_FITXER,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_HIST_SS_PE' AS TABLA_ORIGEN

FROM hashed_source src

{% if is_incremental() %}

LEFT JOIN latest_target target
    ON target.HK_HIST_SS_PE = src.HK_HIST_SS_PE

WHERE target.HK_HIST_SS_PE IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}