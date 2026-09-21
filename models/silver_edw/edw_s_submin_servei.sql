{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT

        UPPER(TRIM(POLISSA_SUBM)) AS POLISSA_SUBM,

        DVER_POLISSA_SUBM,
        TIP_SUBM_SERV,
        SIT_SUBM_SERV,
        DATA_CTE_SUBM_SERV,
        DATA_ALT_SUBM_SERV,
        DATA_RES_SUBM_SERV,
        IMP_FIANSA,
        SIT_FIANSA,
        DATA_ULTIMA_FACT,
        QL_IDIOMA,
        ID_PAGA_IVA,
        US_AIGUA_SUBM,
        NOMB_HABIT_SUBM,
        TIP_HABIT_SUBM,
        TIP_TAXA_TRR,
        POLISSA_RAMAL,
        PIS_PORTA_DESTI,
        DNI_NIF_CLIENT,
        NUM_ENTITAT_COBRA,
        NUM_AGENCIA_APART,
        NUM_COMPTE_DEPEND,
        NOM_TITULAR_COMPTE,
        ID_QUOTA_SOCIAL,
        ID_TARIFA_SOCIAL,
        IND_SERVEI_SOCIAL,
        IND_POB_ENERG,
        NOM_COMERCIAL,
        TIP_FACT_ENV,
        CODI_PAIS,
        NUM_COMPTE_IBAN,
        IND_OKUPA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_submin_servei') }}

    WHERE NULLIF(TRIM(POLISSA_SUBM), '') IS NOT NULL

),

hashed_source AS (

    SELECT

        SHA2_HEX(
            POLISSA_SUBM,
            256
        ) AS HK_SUBMIN_SERVEI,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(NULLIF(TRIM(DVER_POLISSA_SUBM), ''), '^^'),
                COALESCE(NULLIF(TRIM(TIP_SUBM_SERV), ''), '^^'),
                COALESCE(NULLIF(TRIM(SIT_SUBM_SERV), ''), '^^'),
                COALESCE(TO_VARCHAR(DATA_CTE_SUBM_SERV, 'YYYY-MM-DD'), '^^'),
                COALESCE(TO_VARCHAR(DATA_ALT_SUBM_SERV, 'YYYY-MM-DD'), '^^'),
                COALESCE(TO_VARCHAR(DATA_RES_SUBM_SERV, 'YYYY-MM-DD'), '^^'),
                COALESCE(TO_VARCHAR(IMP_FIANSA, 'FM999999999999990.0000'), '^^'),
                COALESCE(NULLIF(TRIM(SIT_FIANSA), ''), '^^'),
                COALESCE(TO_VARCHAR(DATA_ULTIMA_FACT, 'YYYY-MM-DD'), '^^'),
                COALESCE(NULLIF(TRIM(QL_IDIOMA), ''), '^^'),
                COALESCE(NULLIF(TRIM(ID_PAGA_IVA), ''), '^^'),
                COALESCE(NULLIF(TRIM(US_AIGUA_SUBM), ''), '^^'),
                COALESCE(TO_VARCHAR(NOMB_HABIT_SUBM), '^^'),
                COALESCE(NULLIF(TRIM(TIP_HABIT_SUBM), ''), '^^'),
                COALESCE(NULLIF(TRIM(TIP_TAXA_TRR), ''), '^^'),
                COALESCE(NULLIF(TRIM(POLISSA_RAMAL), ''), '^^'),
                COALESCE(NULLIF(TRIM(PIS_PORTA_DESTI), ''), '^^'),
                COALESCE(NULLIF(TRIM(DNI_NIF_CLIENT), ''), '^^'),
                COALESCE(NULLIF(TRIM(NUM_ENTITAT_COBRA), ''), '^^'),
                COALESCE(NULLIF(TRIM(NUM_AGENCIA_APART), ''), '^^'),
                COALESCE(NULLIF(TRIM(NUM_COMPTE_DEPEND), ''), '^^'),
                COALESCE(NULLIF(TRIM(NOM_TITULAR_COMPTE), ''), '^^'),
                COALESCE(NULLIF(TRIM(ID_QUOTA_SOCIAL), ''), '^^'),
                COALESCE(NULLIF(TRIM(ID_TARIFA_SOCIAL), ''), '^^'),
                COALESCE(NULLIF(TRIM(IND_SERVEI_SOCIAL), ''), '^^'),
                COALESCE(NULLIF(TRIM(IND_POB_ENERG), ''), '^^'),
                COALESCE(NULLIF(TRIM(NOM_COMERCIAL), ''), '^^'),
                COALESCE(NULLIF(TRIM(TIP_FACT_ENV), ''), '^^'),
                COALESCE(NULLIF(TRIM(CODI_PAIS), ''), '^^'),
                COALESCE(NULLIF(TRIM(NUM_COMPTE_IBAN), ''), '^^'),
                COALESCE(NULLIF(TRIM(IND_OKUPA), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        POLISSA_SUBM,

        DVER_POLISSA_SUBM,
        TIP_SUBM_SERV,
        SIT_SUBM_SERV,
        DATA_CTE_SUBM_SERV,
        DATA_ALT_SUBM_SERV,
        DATA_RES_SUBM_SERV,
        IMP_FIANSA,
        SIT_FIANSA,
        DATA_ULTIMA_FACT,
        QL_IDIOMA,
        ID_PAGA_IVA,
        US_AIGUA_SUBM,
        NOMB_HABIT_SUBM,
        TIP_HABIT_SUBM,
        TIP_TAXA_TRR,
        POLISSA_RAMAL,
        PIS_PORTA_DESTI,
        DNI_NIF_CLIENT,
        NUM_ENTITAT_COBRA,
        NUM_AGENCIA_APART,
        NUM_COMPTE_DEPEND,
        NOM_TITULAR_COMPTE,
        ID_QUOTA_SOCIAL,
        ID_TARIFA_SOCIAL,
        IND_SERVEI_SOCIAL,
        IND_POB_ENERG,
        NOM_COMERCIAL,
        TIP_FACT_ENV,
        CODI_PAIS,
        NUM_COMPTE_IBAN,
        IND_OKUPA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_SUBMIN_SERVEI,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_SUBMIN_SERVEI
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT

    src.HK_SUBMIN_SERVEI,
    src.HASHDIFF,

    src.POLISSA_SUBM,

    src.DVER_POLISSA_SUBM,
    src.TIP_SUBM_SERV,
    src.SIT_SUBM_SERV,
    src.DATA_CTE_SUBM_SERV,
    src.DATA_ALT_SUBM_SERV,
    src.DATA_RES_SUBM_SERV,
    src.IMP_FIANSA,
    src.SIT_FIANSA,
    src.DATA_ULTIMA_FACT,
    src.QL_IDIOMA,
    src.ID_PAGA_IVA,
    src.US_AIGUA_SUBM,
    src.NOMB_HABIT_SUBM,
    src.TIP_HABIT_SUBM,
    src.TIP_TAXA_TRR,
    src.POLISSA_RAMAL,
    src.PIS_PORTA_DESTI,
    src.DNI_NIF_CLIENT,
    src.NUM_ENTITAT_COBRA,
    src.NUM_AGENCIA_APART,
    src.NUM_COMPTE_DEPEND,
    src.NOM_TITULAR_COMPTE,
    src.ID_QUOTA_SOCIAL,
    src.ID_TARIFA_SOCIAL,
    src.IND_SERVEI_SOCIAL,
    src.IND_POB_ENERG,
    src.NOM_COMERCIAL,
    src.TIP_FACT_ENV,
    src.CODI_PAIS,
    src.NUM_COMPTE_IBAN,
    src.IND_OKUPA,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_SUBMIN_SERVEI' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

LEFT JOIN latest_target AS target
    ON target.HK_SUBMIN_SERVEI = src.HK_SUBMIN_SERVEI

WHERE target.HK_SUBMIN_SERVEI IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}