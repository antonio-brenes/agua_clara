{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(POLISSA_RAMAL)) AS POLISSA_RAMAL,

        DVER_POLISSA_RAMAL,
        SIT_RAMAL,
        TIP_OPER_RAMAL,
        US_RAMAL,
        MATERIAL_RAMAL,
        DATA_INST_RAMAL,
        DIAMETRE_RAMAL,
        SIT_CLAU_PAS,
        DATA_SIG_CTE_RAMAL,
        TIP_SUBM_CTE_RAMAL,
        NOMB_JOC_CLAUS_CTE,
        DATA_PART_INST_RAM,
        NUM_PART_INST_RAM,
        QL_ARQUETA_ARMARI,
        ESTAT_ARQUETA_ARM,
        ID_CIR_RECUP_AIGUA,
        NUM_SOL_LIC_AFEC,
        DATA_SOL_BAIXA_RAM,
        NUM_ORD_RAMAL,
        OBS_PRESA_RAMAL,
        RAMAL_CO,
        QL_TIPUS_DADES_C,
        QL_ANOT,
        SECCIO_CENSAL,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN,

        CONVERT_TIMEZONE(
            'Europe/Madrid',
            CURRENT_TIMESTAMP()
        ) AS FECHA_CARGA

    FROM {{ ref('l4_ramal') }}

    WHERE NULLIF(TRIM(POLISSA_RAMAL), '') IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            POLISSA_RAMAL,
            256
        ) AS HK_RAMAL,

        SHA2_HEX(
            CONCAT_WS(
                '|',

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    DVER_POLISSA_RAMAL
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(SIT_RAMAL)
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(TIP_OPER_RAMAL)
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(US_RAMAL)
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(MATERIAL_RAMAL)
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(
                        DATA_INST_RAMAL,
                        'YYYY-MM-DD'
                    ),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(DIAMETRE_RAMAL),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(SIT_CLAU_PAS)
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(
                        DATA_SIG_CTE_RAMAL,
                        'YYYY-MM-DD'
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    TIP_SUBM_CTE_RAMAL
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NOMB_JOC_CLAUS_CTE),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(
                        DATA_PART_INST_RAM,
                        'YYYY-MM-DD'
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    NUM_PART_INST_RAM
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    QL_ARQUETA_ARMARI
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    ESTAT_ARQUETA_ARM
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    ID_CIR_RECUP_AIGUA
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    NUM_SOL_LIC_AFEC
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(
                        DATA_SOL_BAIXA_RAM,
                        'YYYY-MM-DD'
                    ),
                    '^^'
                ),

                COALESCE(
                    TO_VARCHAR(NUM_ORD_RAMAL),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    OBS_PRESA_RAMAL
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(RAMAL_CO)
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(
                                    QL_TIPUS_DADES_C
                                )
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(QL_ANOT)
                            )
                        ),
                        ''
                    ),
                    '^^'
                ),

                COALESCE(
                    NULLIF(
                        UPPER(
                            TRIM(
                                TO_VARCHAR(SECCIO_CENSAL)
                            )
                        ),
                        ''
                    ),
                    '^^'
                )
            ),
            256
        ) AS HASHDIFF,

        POLISSA_RAMAL,

        DVER_POLISSA_RAMAL,
        SIT_RAMAL,
        TIP_OPER_RAMAL,
        US_RAMAL,
        MATERIAL_RAMAL,
        DATA_INST_RAMAL,
        DIAMETRE_RAMAL,
        SIT_CLAU_PAS,
        DATA_SIG_CTE_RAMAL,
        TIP_SUBM_CTE_RAMAL,
        NOMB_JOC_CLAUS_CTE,
        DATA_PART_INST_RAM,
        NUM_PART_INST_RAM,
        QL_ARQUETA_ARMARI,
        ESTAT_ARQUETA_ARM,
        ID_CIR_RECUP_AIGUA,
        NUM_SOL_LIC_AFEC,
        DATA_SOL_BAIXA_RAM,
        NUM_ORD_RAMAL,
        OBS_PRESA_RAMAL,
        RAMAL_CO,
        QL_TIPUS_DADES_C,
        QL_ANOT,
        SECCIO_CENSAL,

        ID_CARGA,
        FECHA_EXTRACCION,
        FECHA_CARGA,
        SISTEMA_ORIGEN,

        'L4_RAMAL' AS TABLA_ORIGEN

    FROM source_data

),

latest_target AS (

    {% if is_incremental() %}

    SELECT
        HK_RAMAL,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_RAMAL
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

    {% else %}

    SELECT
        CAST(NULL AS VARCHAR) AS HK_RAMAL,
        CAST(NULL AS VARCHAR) AS HASHDIFF

    WHERE 1 = 0

    {% endif %}

)

SELECT
    src.HK_RAMAL,
    src.HASHDIFF,

    src.POLISSA_RAMAL,

    src.DVER_POLISSA_RAMAL,
    src.SIT_RAMAL,
    src.TIP_OPER_RAMAL,
    src.US_RAMAL,
    src.MATERIAL_RAMAL,
    src.DATA_INST_RAMAL,
    src.DIAMETRE_RAMAL,
    src.SIT_CLAU_PAS,
    src.DATA_SIG_CTE_RAMAL,
    src.TIP_SUBM_CTE_RAMAL,
    src.NOMB_JOC_CLAUS_CTE,
    src.DATA_PART_INST_RAM,
    src.NUM_PART_INST_RAM,
    src.QL_ARQUETA_ARMARI,
    src.ESTAT_ARQUETA_ARM,
    src.ID_CIR_RECUP_AIGUA,
    src.NUM_SOL_LIC_AFEC,
    src.DATA_SOL_BAIXA_RAM,
    src.NUM_ORD_RAMAL,
    src.OBS_PRESA_RAMAL,
    src.RAMAL_CO,
    src.QL_TIPUS_DADES_C,
    src.QL_ANOT,
    src.SECCIO_CENSAL,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,
    src.FECHA_CARGA,
    src.SISTEMA_ORIGEN,
    src.TABLA_ORIGEN

FROM hashed_source AS src

LEFT JOIN latest_target AS tgt
    ON tgt.HK_RAMAL = src.HK_RAMAL

WHERE tgt.HK_RAMAL IS NULL
   OR tgt.HASHDIFF <> src.HASHDIFF