{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(m.NUM_MUN_SGAB)) AS NUM_MUN_SGAB,

        m.NOM_MUN_SGAB,
        m.QL_CRITERI_FACT,
        m.ID_MUN_CP_UNIC,
        m.CP_PROVINCIA,
        m.UNITAT_REPARTIMENT,
        m.NUM_DTE_POST,
        m.NUM_DEL_SGAB,
        m.NUM_AGENCIA_SGAB,
        m.ID_AREA_LECT,
        m.ID_EMPRESA,
        m.DELEGA_CO,
        m.QL_GEST_DTE,
        m.ID_MUNI_ENT_MET,
        m.NOMB_DIES_ANS,
        m.MUNI_GENERALITAT,
        m.CODI_PROV,
        m.CODI_MUNI,
        m.QL_TIPUS_VENDA,
        m.CODI_MUNICIPI,
        m.NOMB_DIES_INDEMN,
        m.NOMB_DIES_SENSE_AUT,
        m.ADHERIT_L24,
        m.CARTA_CIRER,
        m.NUM_CAIPS,
        m.NUM_DIAS_ENV_CAIPS,
        m.CARTA_CIRER_2,
        m.NUM_DIAS_CIRER_2,
        m.NUM_DIAS_GENERA_CORTE,

        m.ID_CARGA,
        m.FECHA_EXTRACCION,
        m.SISTEMA_ORIGEN

    FROM {{ ref('l4_municipi_sgab') }} AS m

    WHERE NULLIF(TRIM(m.NUM_MUN_SGAB), '') IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            NUM_MUN_SGAB,
            256
        ) AS HK_MUNICIPI_SGAB,

        SHA2_HEX(
            CONCAT_WS(
                '|',

                COALESCE(
                    NULLIF(UPPER(TRIM(NOM_MUN_SGAB)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(QL_CRITERI_FACT)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(ID_MUN_CP_UNIC)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(CP_PROVINCIA)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(UNITAT_REPARTIMENT)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(NUM_DTE_POST)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(NUM_DEL_SGAB)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(NUM_AGENCIA_SGAB)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(ID_AREA_LECT)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(ID_EMPRESA)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(DELEGA_CO)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(QL_GEST_DTE)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(ID_MUNI_ENT_MET)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NOMB_DIES_ANS),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(MUNI_GENERALITAT)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(CODI_PROV)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(CODI_MUNI)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(TRIM(QL_TIPUS_VENDA)),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(CODI_MUNICIPI)), ''),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NOMB_DIES_INDEMN),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NOMB_DIES_SENSE_AUT),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(ADHERIT_L24)), ''),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(CARTA_CIRER)), ''),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NUM_CAIPS),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NUM_DIAS_ENV_CAIPS),
                    '^^'
                ),

                COALESCE(
                    NULLIF(UPPER(TRIM(CARTA_CIRER_2)), ''),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NUM_DIAS_CIRER_2),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NUM_DIAS_GENERA_CORTE),
                    '^^'
                )
            ),
            256
        ) AS HASHDIFF,

        NUM_MUN_SGAB,

        NOM_MUN_SGAB,
        QL_CRITERI_FACT,
        ID_MUN_CP_UNIC,
        CP_PROVINCIA,
        UNITAT_REPARTIMENT,
        NUM_DTE_POST,
        NUM_DEL_SGAB,
        NUM_AGENCIA_SGAB,
        ID_AREA_LECT,
        ID_EMPRESA,
        DELEGA_CO,
        QL_GEST_DTE,
        ID_MUNI_ENT_MET,
        NOMB_DIES_ANS,
        MUNI_GENERALITAT,
        CODI_PROV,
        CODI_MUNI,
        QL_TIPUS_VENDA,
        CODI_MUNICIPI,
        NOMB_DIES_INDEMN,
        NOMB_DIES_SENSE_AUT,
        ADHERIT_L24,
        CARTA_CIRER,
        NUM_CAIPS,
        NUM_DIAS_ENV_CAIPS,
        CARTA_CIRER_2,
        NUM_DIAS_CIRER_2,
        NUM_DIAS_GENERA_CORTE,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_MUNICIPI_SGAB,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_MUNICIPI_SGAB
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT
    src.HK_MUNICIPI_SGAB,
    src.HASHDIFF,

    src.NUM_MUN_SGAB,

    src.NOM_MUN_SGAB,
    src.QL_CRITERI_FACT,
    src.ID_MUN_CP_UNIC,
    src.CP_PROVINCIA,
    src.UNITAT_REPARTIMENT,
    src.NUM_DTE_POST,
    src.NUM_DEL_SGAB,
    src.NUM_AGENCIA_SGAB,
    src.ID_AREA_LECT,
    src.ID_EMPRESA,
    src.DELEGA_CO,
    src.QL_GEST_DTE,
    src.ID_MUNI_ENT_MET,
    src.NOMB_DIES_ANS,
    src.MUNI_GENERALITAT,
    src.CODI_PROV,
    src.CODI_MUNI,
    src.QL_TIPUS_VENDA,
    src.CODI_MUNICIPI,
    src.NOMB_DIES_INDEMN,
    src.NOMB_DIES_SENSE_AUT,
    src.ADHERIT_L24,
    src.CARTA_CIRER,
    src.NUM_CAIPS,
    src.NUM_DIAS_ENV_CAIPS,
    src.CARTA_CIRER_2,
    src.NUM_DIAS_CIRER_2,
    src.NUM_DIAS_GENERA_CORTE,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_MUNICIPI_SGAB' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_MUNICIPI_SGAB =
       src.HK_MUNICIPI_SGAB

WHERE target.HK_MUNICIPI_SGAB IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}