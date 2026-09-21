{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_RECUP',
    schema='silver_fact',
    tags=['silver_fact', 'facturacion', 'recuperacion']
) }}

WITH source_data AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS(
                '|',
                UPPER(TRIM(r.ID_EMPRESA)),
                UPPER(TRIM(r.ANY_FACTURA)),
                TO_VARCHAR(r.NUM_FACTURA)
            ),
            256
        ) AS HK_FACTURA_RECUP,

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
        r.IMP_QTA_SERV_RC,
        r.M3_BLOC1_RC,
        r.PREU_M3_BLOC1_RC,
        r.IMP_BLOC1_RC,
        r.M3_BLOC2_RC,
        r.PREU_M3_BLOC2_RC,
        r.IMP_BLOC2_RC,
        r.M3_BLOC3_RC,
        r.PREU_M3_BLOC3_RC,
        r.IMP_BLOC3_RC,
        r.BASE_CT_XBASICA_RC,
        r.PREU_CT_XBASICA_RC,
        r.IMP_CT_XBASICA_RC,
        r.BASE_TCG_SUBM_RC,
        r.PREU_TCG_SUBM_RC,
        r.IMP_TCG_SUBM_RC,
        r.BASE_CLAVAG_RC,
        r.PREU_CLAVAG_RC,
        r.IMP_CLAVAG_RC,
        r.BASE_SANEJA_RC,
        r.PREU_SANEJA_RC,
        r.IMP_SANEJA_RC,
        r.BASE_ERSU_RC,
        r.PREU_ERSU_RC,
        r.IMP_ERSU_RC,
        r.BASE_CIH_BLOC1_RC,
        r.PREU_CIH_BLOC1_RC,
        r.IMP_CIH_BLOC1_RC,
        r.BASE_CIH_BLOC2_RC,
        r.PREU_CIH_BLOC2_RC,
        r.IMP_CIH_BLOC2_RC,
        r.BASE_CIH_BLOC3_RC,
        r.PREU_CIH_BLOC3_RC,
        r.IMP_CIH_BLOC3_RC,
        r.IMP_BONIF_QTA_RC,
        r.BASE_CAI_T1_RC,
        r.PREU_CAI_T1_RC,
        r.IMP_CAI_T1_RC,
        r.BASE_CAI_T2_RC,
        r.PREU_CAI_T2_RC,
        r.IMP_CAI_T2_RC,
        r.BASE_CLA_T2_RC,
        r.PREU_CLA_T2_RC,
        r.IMP_CLA_T2_RC,
        r.BASE_CAI_T3_RC,
        r.PREU_CAI_T3_RC,
        r.IMP_CAI_T3_RC,

        COALESCE(r.M3_BLOC1_RC, 0)
            + COALESCE(r.M3_BLOC2_RC, 0)
            + COALESCE(r.M3_BLOC3_RC, 0) AS M3_TOTAL_RECUPERADOS,

        COALESCE(r.IMP_QTA_SERV_RC, 0)
            + COALESCE(r.IMP_BLOC1_RC, 0)
            + COALESCE(r.IMP_BLOC2_RC, 0)
            + COALESCE(r.IMP_BLOC3_RC, 0)
            + COALESCE(r.IMP_CT_XBASICA_RC, 0)
            + COALESCE(r.IMP_TCG_SUBM_RC, 0)
            + COALESCE(r.IMP_CLAVAG_RC, 0)
            + COALESCE(r.IMP_SANEJA_RC, 0)
            + COALESCE(r.IMP_ERSU_RC, 0)
            + COALESCE(r.IMP_CIH_BLOC1_RC, 0)
            + COALESCE(r.IMP_CIH_BLOC2_RC, 0)
            + COALESCE(r.IMP_CIH_BLOC3_RC, 0)
            + COALESCE(r.IMP_BONIF_QTA_RC, 0)
            + COALESCE(r.IMP_CAI_T1_RC, 0)
            + COALESCE(r.IMP_CAI_T2_RC, 0)
            + COALESCE(r.IMP_CLA_T2_RC, 0)
            + COALESCE(r.IMP_CAI_T3_RC, 0) AS IMP_TOTAL_RECUPERACION,

        r.ID_CARGA,
        r.FECHA_EXTRACCION,
        CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
        r.SISTEMA_ORIGEN,
        'L4_FACT_RECUP' AS TABLA_ORIGEN

    FROM {{ ref('l4_fact_recup') }} AS r

        WHERE NULLIF(TRIM(r.ID_EMPRESA), '') IS NOT NULL
            AND NULLIF(TRIM(r.ANY_FACTURA), '') IS NOT NULL
      AND r.NUM_FACTURA IS NOT NULL

)

SELECT *
FROM source_data
