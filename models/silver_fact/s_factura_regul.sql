{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_REGUL',
    schema='silver_fact',
    tags=['silver_fact', 'facturacion', 'regularizacion']
) }}

WITH source_data AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS(
                '|',
                UPPER(TRIM(r.ID_EMPRESA)),
                UPPER(TRIM(r.ANY_FACTURA)),
                TO_VARCHAR(r.NUM_FACTURA),
                TO_VARCHAR(r.DATA_FIN_PER_INCID, 'YYYY-MM-DD')
            ),
            256
        ) AS HK_FACTURA_REGUL,

        SHA2_HEX(
            CONCAT_WS(
                '|',
                UPPER(TRIM(r.ID_EMPRESA)),
                UPPER(TRIM(r.ANY_FACTURA)),
                TO_VARCHAR(r.NUM_FACTURA)
            ),
            256
        ) AS HK_FACTURA,

        r.ID_EMPRESA,
        r.ANY_FACTURA,
        r.NUM_FACTURA,
        r.DATA_FIN_PER_INCID,
        r.M3_BLOC1_RG,
        r.PREU_M3_BLOC1_RG,
        r.IMP_BLOC1_RG,
        r.M3_BLOC2_RG,
        r.PREU_M3_BLOC2_RG,
        r.IMP_BLOC2_RG,
        r.M3_BLOC3_RG,
        r.PREU_M3_BLOC3_RG,
        r.IMP_BLOC3_RG,
        r.TIP_CT_XBASICA_RG,
        r.BASE_CT_XBASICA_RG,
        r.PREU_CT_XBASICA_RG,
        r.IMP_CT_XBASICA_RG,
        r.TIP_TCG_SUBM_RG,
        r.BASE_TCG_SUBM_RG,
        r.PREU_TCG_SUBM_RG,
        r.IMP_TCG_SUBM_RG,
        r.BASE_CTG_SUBM_RG,
        r.PERCEN_CTG_SUBM_RG,
        r.IMP_CTG_SUBM_RG,
        r.IMP_CAN_BAELLS_RG,
        r.IMP_CAN_TER_RG,
        r.IMP_PRODUC_BRUT_RG,
        r.TIP_CLAVAG_RG,
        r.BASE_CLAVAG_RG,
        r.PREU_CLAVAG_RG,
        r.IMP_CLAVAG_RG,
        r.TIP_SANEJA_RG,
        r.BASE_SANEJA_RG,
        r.PREU_SANEJA_RG,
        r.IMP_SANEJA_RG,
        r.TIP_ERSU_RG,
        r.BASE_ERSU_RG,
        r.PREU_ERSU_RG,
        r.IMP_ERSU_RG,
        r.TIP_CIH_RG,
        r.BASE_CIH_BLOC1_RG,
        r.PREU_CIH_BLOC1_RG,
        r.IMP_CIH_BLOC1_RG,
        r.BASE_CIH_BLOC2_RG,
        r.PREU_CIH_BLOC2_RG,
        r.IMP_CIH_BLOC2_RG,
        r.BASE_CIH_BLOC3_RG,
        r.PREU_CIH_BLOC3_RG,
        r.IMP_CIH_BLOC3_RG,
        r.TIP_CAI_RG,
        r.BASE_CAI_T1_RG,
        r.PREU_CAI_T1_RG,
        r.IMP_CAI_T1_RG,
        r.BASE_CAI_T2_RG,
        r.PREU_CAI_T2_RG,
        r.IMP_CAI_T2_RG,
        r.COEF_CAI_RG,
        r.BASE_CLA_T2_RG,
        r.PREU_CLA_T2_RG,
        r.IMP_CLA_T2_RG,
        r.BASE_CAI_T3_RG,
        r.PREU_CAI_T3_RG,
        r.IMP_CAI_T3_RG,
        r.BASE_CAI_T4_RG,
        r.PREU_CAI_T4_RG,
        r.IMP_CAI_T4_RG,
        r.M3_BLOC4_RG,
        r.PREU_M3_BLOC4_RG,
        r.IMP_BLOC4_RG,
        r.M3_BLOC5_RG,
        r.PREU_M3_BLOC5_RG,
        r.IMP_BLOC5_RG,

        COALESCE(r.M3_BLOC1_RG, 0)
            + COALESCE(r.M3_BLOC2_RG, 0)
            + COALESCE(r.M3_BLOC3_RG, 0)
            + COALESCE(r.M3_BLOC4_RG, 0)
            + COALESCE(r.M3_BLOC5_RG, 0) AS M3_TOTAL_REGULARIZADOS,

        COALESCE(r.IMP_BLOC1_RG, 0)
            + COALESCE(r.IMP_BLOC2_RG, 0)
            + COALESCE(r.IMP_BLOC3_RG, 0)
            + COALESCE(r.IMP_BLOC4_RG, 0)
            + COALESCE(r.IMP_BLOC5_RG, 0)
            + COALESCE(r.IMP_CT_XBASICA_RG, 0)
            + COALESCE(r.IMP_TCG_SUBM_RG, 0)
            + COALESCE(r.IMP_CTG_SUBM_RG, 0)
            + COALESCE(r.IMP_CAN_BAELLS_RG, 0)
            + COALESCE(r.IMP_CAN_TER_RG, 0)
            + COALESCE(r.IMP_PRODUC_BRUT_RG, 0)
            + COALESCE(r.IMP_CLAVAG_RG, 0)
            + COALESCE(r.IMP_SANEJA_RG, 0)
            + COALESCE(r.IMP_ERSU_RG, 0)
            + COALESCE(r.IMP_CIH_BLOC1_RG, 0)
            + COALESCE(r.IMP_CIH_BLOC2_RG, 0)
            + COALESCE(r.IMP_CIH_BLOC3_RG, 0)
            + COALESCE(r.IMP_CAI_T1_RG, 0)
            + COALESCE(r.IMP_CAI_T2_RG, 0)
            + COALESCE(r.IMP_CLA_T2_RG, 0)
            + COALESCE(r.IMP_CAI_T3_RG, 0)
            + COALESCE(r.IMP_CAI_T4_RG, 0) AS IMP_TOTAL_REGULARIZACION,

        r.ID_CARGA,
        r.FECHA_EXTRACCION,
        CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
        r.SISTEMA_ORIGEN,
        'L4_FACT_REGUL' AS TABLA_ORIGEN

    FROM {{ ref('l4_fact_regul') }} AS r

        WHERE NULLIF(TRIM(r.ID_EMPRESA), '') IS NOT NULL
            AND NULLIF(TRIM(r.ANY_FACTURA), '') IS NOT NULL
      AND r.NUM_FACTURA IS NOT NULL
      AND r.DATA_FIN_PER_INCID IS NOT NULL

)

SELECT *
FROM source_data
