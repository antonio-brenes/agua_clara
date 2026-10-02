{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'link']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(f.NUM_MUN_SGAB)) AS NUM_MUN_SGAB,
        TO_VARCHAR(f.NUM_CARRER) AS NUM_CARRER,
        UPPER(TRIM(f.NUM_INI_FINCA)) AS NUM_INI_FINCA,
        NULLIF(UPPER(TRIM(f.COMP_NUM_INI_FINCA)), '') AS COMP_NUM_INI_FINCA,
        UPPER(TRIM(f.NUM_FIN_FINCA)) AS NUM_FIN_FINCA,
        NULLIF(UPPER(TRIM(f.COMP_NUM_FIN_FINCA)), '') AS COMP_NUM_FIN_FINCA,
        UPPER(TRIM(f.SIT_FINCA_ESPEC)) AS SIT_FINCA_ESPEC,
        UPPER(TRIM(f.ORD_FINCA_ESPEC)) AS ORD_FINCA_ESPEC,

        f.ID_CARGA,
        f.FECHA_EXTRACCION,
        f.SISTEMA_ORIGEN

    FROM {{ ref('l4_finca') }} AS f

    WHERE NULLIF(TRIM(f.NUM_MUN_SGAB), '') IS NOT NULL
    AND f.NUM_CARRER IS NOT NULL
      AND NULLIF(TRIM(f.NUM_INI_FINCA), '') IS NOT NULL
      AND NULLIF(TRIM(f.NUM_FIN_FINCA), '') IS NOT NULL
      AND NULLIF(TRIM(f.SIT_FINCA_ESPEC), '') IS NOT NULL
      AND NULLIF(TRIM(f.ORD_FINCA_ESPEC), '') IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS(
                '|',
                NUM_MUN_SGAB,
                NUM_CARRER,
                NUM_INI_FINCA,
                COALESCE(COMP_NUM_INI_FINCA,'^^'),
                NUM_FIN_FINCA,
                COALESCE(COMP_NUM_FIN_FINCA,'^^'),
                SIT_FINCA_ESPEC,
                ORD_FINCA_ESPEC
            ),
            256
        ) AS HK_CARRER_FINCA,

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
                NUM_MUN_SGAB,
                NUM_CARRER,
                NUM_INI_FINCA,
                COALESCE(COMP_NUM_INI_FINCA,'^^'),
                NUM_FIN_FINCA,
                COALESCE(COMP_NUM_FIN_FINCA,'^^'),
                SIT_FINCA_ESPEC,
                ORD_FINCA_ESPEC
            ),
            256
        ) AS HK_FINCA,

        NUM_MUN_SGAB,
        NUM_CARRER,
        NUM_INI_FINCA,
        COMP_NUM_INI_FINCA,
        NUM_FIN_FINCA,
        COMP_NUM_FIN_FINCA,
        SIT_FINCA_ESPEC,
        ORD_FINCA_ESPEC,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT
    src.HK_CARRER_FINCA,
    src.HK_CARRER,
    src.HK_FINCA,

    src.NUM_MUN_SGAB,
    src.NUM_CARRER,
    src.NUM_INI_FINCA,
    src.COMP_NUM_INI_FINCA,
    src.NUM_FIN_FINCA,
    src.COMP_NUM_FIN_FINCA,
    src.SIT_FINCA_ESPEC,
    src.ORD_FINCA_ESPEC,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_FINCA' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} AS target
    WHERE target.HK_CARRER_FINCA =
          src.HK_CARRER_FINCA

)

{% endif %}