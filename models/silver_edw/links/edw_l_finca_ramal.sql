{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'link']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(r.POLISSA_RAMAL)) AS POLISSA_RAMAL,
        UPPER(TRIM(r.NUM_MUN_SGAB)) AS NUM_MUN_SGAB,
        TO_VARCHAR(r.NUM_CARRER) AS NUM_CARRER,
        UPPER(TRIM(r.NUM_INI_FINCA)) AS NUM_INI_FINCA,
        NULLIF(UPPER(TRIM(r.COMP_NUM_INI_FINCA)), '') AS COMP_NUM_INI_FINCA,
        UPPER(TRIM(r.NUM_FIN_FINCA)) AS NUM_FIN_FINCA,
        NULLIF(UPPER(TRIM(r.COMP_NUM_FIN_FINCA)), '') AS COMP_NUM_FIN_FINCA,
        UPPER(TRIM(r.SIT_FINCA_ESPEC)) AS SIT_FINCA_ESPEC,
        UPPER(TRIM(r.ORD_FINCA_ESPEC)) AS ORD_FINCA_ESPEC,

        r.ID_CARGA,
        r.FECHA_EXTRACCION,
        r.SISTEMA_ORIGEN,

        CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA

    FROM {{ ref('l4_ramal') }} as r

    WHERE NULLIF(TRIM(r.POLISSA_RAMAL), '') IS NOT NULL
      AND NULLIF(TRIM(r.NUM_MUN_SGAB), '') IS NOT NULL
      AND r.NUM_CARRER IS NOT NULL
      AND NULLIF(TRIM(r.NUM_INI_FINCA), '') IS NOT NULL
      AND NULLIF(TRIM(r.NUM_FIN_FINCA), '') IS NOT NULL
      AND NULLIF(TRIM(r.SIT_FINCA_ESPEC), '') IS NOT NULL
      AND NULLIF(TRIM(r.ORD_FINCA_ESPEC), '') IS NOT NULL

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
                ORD_FINCA_ESPEC,
                POLISSA_RAMAL
            ),
            256
        ) AS HK_FINCA_RAMAL,

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

        SHA2_HEX(
            POLISSA_RAMAL,
            256
        ) AS HK_RAMAL,

        NUM_MUN_SGAB,
        NUM_CARRER,
        NUM_INI_FINCA,
        COMP_NUM_INI_FINCA,
        NUM_FIN_FINCA,
        COMP_NUM_FIN_FINCA,
        SIT_FINCA_ESPEC,
        ORD_FINCA_ESPEC,        

        POLISSA_RAMAL,

        ID_CARGA,
        FECHA_EXTRACCION,
        FECHA_CARGA,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT
    src.HK_FINCA_RAMAL,
    src.HK_FINCA,
    src.HK_RAMAL,

    src.NUM_MUN_SGAB,
    src.NUM_CARRER,
    src.NUM_INI_FINCA,
    src.COMP_NUM_INI_FINCA,
    src.NUM_FIN_FINCA,
    src.COMP_NUM_FIN_FINCA,
    src.SIT_FINCA_ESPEC,
    src.ORD_FINCA_ESPEC,

    src.POLISSA_RAMAL,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,
    src.FECHA_CARGA,
    src.SISTEMA_ORIGEN,
    'L4_RAMAL' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} AS tgt

    WHERE tgt.HK_FINCA_RAMAL =
          src.HK_FINCA_RAMAL

)

{% endif %}