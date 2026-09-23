{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA',
    schema='silver_fact',
    tags=['silver_fact', 'facturacion']
) }}

-- depends_on: {{ ref('edw_h_submin_servei') }}
-- depends_on: {{ ref('edw_h_tipo_suministro') }}
-- depends_on: {{ ref('edw_h_tipo_uso_agua') }}
-- depends_on: {{ ref('edw_h_tipo_vivienda') }}

WITH source_data AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS(
                '|',
                TO_VARCHAR(f.NUM_PARTICIO),
                UPPER(TRIM(f.ID_EMPRESA)),
                UPPER(TRIM(f.ANY_FACTURA)),
                TO_VARCHAR(f.NUM_FACTURA)
            ),
            256
        ) AS HK_FACTURA,

        SHA2_HEX(
            UPPER(TRIM(f.POLISSA_SUBM)),
            256
        ) AS HK_SUBMIN_SERVEI,

        SHA2_HEX(UPPER(TRIM(f.TIP_SUBM_SERV)), 256)
            AS HK_TIPO_SUMINISTRO,

        SHA2_HEX(UPPER(TRIM(f.US_AIGUA_SUBM_FACT)), 256)
            AS HK_TIPO_USO_AGUA,

        SHA2_HEX(UPPER(TRIM(f.TIP_HABIT_SUBM_FA)), 256)
            AS HK_TIPO_VIVIENDA,

        f.NUM_PARTICIO,
        f.ID_EMPRESA,
        f.ANY_FACTURA,
        f.NUM_FACTURA,
        f.POLISSA_SUBM,

        f.DATA_INI_FACT,
        f.DATA_FIN_FACT,
        f.DATA_EMISS_FACT,
        f.DATA_CARREC_RECAP,
        f.ANY_CALENDARI,
        f.MES_CALENDARI,
        f.FREQ_FACT,
        DATEDIFF('day', f.DATA_INI_FACT, f.DATA_FIN_FACT) + 1 AS DIES_FACTURATS,

        f.TIP_SUBM_SERV,
        f.US_AIGUA_SUBM_FACT,
        f.TIP_HABIT_SUBM_FA,
        f.NOMB_HABIT_FACT,
        f.SIT_SUBM_SERV_FACT,
        f.TIP_DOMESTIC,

        COALESCE(f.M3_BLOC1, 0)
            + COALESCE(f.M3_BLOC2, 0)
            + COALESCE(f.M3_BLOC3, 0)
            + COALESCE(f.M3_BLOC4, 0)
            + COALESCE(f.M3_BLOC5, 0) AS CONSUM_TOTAL_M3,

        f.IMP_TOTAL_FACT,
        f.IMP_AIGUA_IVA,

        f.ID_RECUPERACIO,
        f.ID_REGULARITZACIO,
        f.ID_CONCEPTES,
        f.ID_DECLARADA,
        f.APROVADA_FACT,
        f.QL_RESUM_COMPTABLE,
        f.ID_CALCUL_DIARI,
        f.QL_DCL_CAI,

        f.TIP_FACTURA,
        f.TIPUS_FACTURA,
        f.TIP_FACT_SII,
        f.QL_MONEDA,
        f.EMISSORA,
        f.PUBLI_OFI_TARI_FA,

        f.QL_GESTIO_FACT,
        f.QL_EMPLEAT_SGAB,
        f.QL_IDIOMA_FACT,
        f.TIP_FACT_ENV,
        f.QL_ENVIO_FACT,

        f.QL_TIP_COBRA,
        f.QL_TIP_COBRA_INI,
        f.ID_CARREC_SOCIETAT,
        f.NUM_ENTITAT_COBR,
        f.NUM_AGENCIA_APAR,
        f.NUM_COMPTE_DEPEN,
        f.DVER_COMPTE_BANC,
        f.NUM_COMPTE_IBAN,

        f.DNI_NIF_CLIENT,
        f.NOM_CLIENT,

        f.IDEN_LOT_LECT_FACT,
        f.ID_LOT_FACT,
        f.NUM_INDEX,
        f.TIP_QTA_SERV_FACT,

        f.ID_CARGA,
        f.FECHA_EXTRACCION,
        CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
        f.SISTEMA_ORIGEN,
        'L4_FACT_RESUM' AS TABLA_ORIGEN

    FROM {{ ref('l4_fact_resum') }} AS f

        WHERE f.NUM_PARTICIO IS NOT NULL
          AND NULLIF(TRIM(f.ID_EMPRESA), '') IS NOT NULL
          AND NULLIF(TRIM(f.ANY_FACTURA), '') IS NOT NULL
          AND f.NUM_FACTURA IS NOT NULL

)

SELECT *
FROM source_data
