{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
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

        f.NUM_TORN_LECT_MENS,
        f.ORD_FINCA_TORN_MEN,
        f.NUM_DTE_POST_FINCA,
        f.ESTAT_FINCA,
        f.ID_GRUP_ELEV_FINCA,
        f.PRES_XARXA_FINCA,
        f.CAT_FISCAL_FINCA,
        f.ALTURA_FINCA,
        f.ID_FINCA_RENDA_LIM,
        f.NUM_EXP_RENDA_LIM,
        f.NUM_ZONA_RECOR,
        f.NUM_TRAVES,
        f.CASA_RECOR_PERIOD,
        f.NUM_NUS_XARXA,
        f.ID_LOT_LECT,
        f.OBS_ADRE_INCOMPLET,
        f.PARTICULARIT_FINCA,
        f.LOCAL_CLAUS_FINCA,
        f.QL_COMPT_ELECTRON,
        f.NUM_DTE_MUNI_FINCA,
        f.QL_BATERIA_CABLE,
        f.CODI_UBICACIO_SAP,

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
        ) AS HK_FINCA,

        SHA2_HEX(
            CONCAT_WS(
                '|',

                COALESCE(
                    NULLIF(
                        TO_VARCHAR(NUM_TORN_LECT_MENS),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        TO_VARCHAR(ORD_FINCA_TORN_MEN),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(NUM_DTE_POST_FINCA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(ESTAT_FINCA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(ID_GRUP_ELEV_FINCA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        TO_VARCHAR(PRES_XARXA_FINCA),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(CAT_FISCAL_FINCA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        TO_VARCHAR(ALTURA_FINCA),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(ID_FINCA_RENDA_LIM)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(NUM_EXP_RENDA_LIM)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(NUM_ZONA_RECOR)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        TO_VARCHAR(NUM_TRAVES),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(CASA_RECOR_PERIOD)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        TO_VARCHAR(NUM_NUS_XARXA),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(ID_LOT_LECT)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(OBS_ADRE_INCOMPLET)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(PARTICULARIT_FINCA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(LOCAL_CLAUS_FINCA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(QL_COMPT_ELECTRON)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(NUM_DTE_MUNI_FINCA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(QL_BATERIA_CABLE)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(CODI_UBICACIO_SAP)),
                        ''
                    ),
                    '^^'
                )
            ),
            256
        ) AS HASHDIFF,

        NUM_MUN_SGAB,
        NUM_CARRER,
        NUM_INI_FINCA,
        COMP_NUM_INI_FINCA,
        NUM_FIN_FINCA,
        COMP_NUM_FIN_FINCA,
        SIT_FINCA_ESPEC,
        ORD_FINCA_ESPEC,

        NUM_TORN_LECT_MENS,
        ORD_FINCA_TORN_MEN,
        NUM_DTE_POST_FINCA,
        ESTAT_FINCA,
        ID_GRUP_ELEV_FINCA,
        PRES_XARXA_FINCA,
        CAT_FISCAL_FINCA,
        ALTURA_FINCA,
        ID_FINCA_RENDA_LIM,
        NUM_EXP_RENDA_LIM,
        NUM_ZONA_RECOR,
        NUM_TRAVES,
        CASA_RECOR_PERIOD,
        NUM_NUS_XARXA,
        ID_LOT_LECT,
        OBS_ADRE_INCOMPLET,
        PARTICULARIT_FINCA,
        LOCAL_CLAUS_FINCA,
        QL_COMPT_ELECTRON,
        NUM_DTE_MUNI_FINCA,
        QL_BATERIA_CABLE,
        CODI_UBICACIO_SAP,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_FINCA,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_FINCA
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT
    src.HK_FINCA,
    src.HASHDIFF,

    src.NUM_MUN_SGAB,
    src.NUM_CARRER,
    src.NUM_INI_FINCA,
    src.COMP_NUM_INI_FINCA,
    src.NUM_FIN_FINCA,
    src.COMP_NUM_FIN_FINCA,
    src.SIT_FINCA_ESPEC,
    src.ORD_FINCA_ESPEC,

    src.NUM_TORN_LECT_MENS,
    src.ORD_FINCA_TORN_MEN,
    src.NUM_DTE_POST_FINCA,
    src.ESTAT_FINCA,
    src.ID_GRUP_ELEV_FINCA,
    src.PRES_XARXA_FINCA,
    src.CAT_FISCAL_FINCA,
    src.ALTURA_FINCA,
    src.ID_FINCA_RENDA_LIM,
    src.NUM_EXP_RENDA_LIM,
    src.NUM_ZONA_RECOR,
    src.NUM_TRAVES,
    src.CASA_RECOR_PERIOD,
    src.NUM_NUS_XARXA,
    src.ID_LOT_LECT,
    src.OBS_ADRE_INCOMPLET,
    src.PARTICULARIT_FINCA,
    src.LOCAL_CLAUS_FINCA,
    src.QL_COMPT_ELECTRON,
    src.NUM_DTE_MUNI_FINCA,
    src.QL_BATERIA_CABLE,
    src.CODI_UBICACIO_SAP,

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

LEFT JOIN latest_target AS target
    ON target.HK_FINCA = src.HK_FINCA

WHERE target.HK_FINCA IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}