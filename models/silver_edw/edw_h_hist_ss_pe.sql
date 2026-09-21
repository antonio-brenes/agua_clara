{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'hub']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,
        UPPER(TRIM(TIP_COLECTIVO)) AS TIP_COLECTIVO,
        TS_MOM_IND,

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

        POLISSA_SUBM,
        TIP_COLECTIVO,
        TS_MOM_IND,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT

    src.HK_HIST_SS_PE,

    src.POLISSA_SUBM,
    src.TIP_COLECTIVO,
    src.TS_MOM_IND,

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

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} tgt
    WHERE tgt.HK_HIST_SS_PE = src.HK_HIST_SS_PE

)

{% endif %}
