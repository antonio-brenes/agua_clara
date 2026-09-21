{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_SERVEI_FACTURAR',
    schema='silver_fact',
    tags=['silver_fact', 'facturacion', 'ci']
) }}

-- depends_on: {{ ref('edw_h_submin_servei') }}

WITH source_data AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS(
                '|',
                UPPER(TRIM(sf.POLISSA_SUBM)),
                TO_VARCHAR(sf.DATA_FIN_FACT, 'YYYY-MM-DD')
            ),
            256
        ) AS HK_SERVEI_FACTURAR,

        SHA2_HEX(
            UPPER(TRIM(sf.POLISSA_SUBM)),
            256
        ) AS HK_SUBMIN_SERVEI,

        sf.POLISSA_SUBM,
        DATEADD('day', 1 - sf.DIES_CONSUM_SERV, sf.DATA_FIN_FACT) AS DATA_INI_FACT,
        sf.DATA_FIN_FACT,
        sf.CALCUL_CONSUM_SERV,
        sf.DIES_CONSUM_SERV,

        sf.NOMB_BOQ_25_SERV,
        sf.NOMB_BOQ_45_SERV,
        sf.NOMB_BOQ_70_SERV,
        sf.NOMB_BOQ_100_SERV,
        sf.NOMB_SPRINCK_SERV,

        COALESCE(sf.NOMB_BOQ_25_SERV, 0)
            + COALESCE(sf.NOMB_BOQ_45_SERV, 0)
            + COALESCE(sf.NOMB_BOQ_70_SERV, 0)
            + COALESCE(sf.NOMB_BOQ_100_SERV, 0) AS NOMB_TOTAL_BOQUES,

        sf.ID_BUTLLETA,
        sf.ID_LOT_LECT,
        sf.ANY_CALENDARI,
        sf.MES_CALENDARI,

        sf.ID_CARGA,
        sf.FECHA_EXTRACCION,
        CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
        sf.SISTEMA_ORIGEN,
        'L4_SERVEI_FACTURAR' AS TABLA_ORIGEN

    FROM {{ ref('l4_servei_facturar') }} AS sf

    WHERE NULLIF(TRIM(sf.POLISSA_SUBM), '') IS NOT NULL
      AND sf.DATA_FIN_FACT IS NOT NULL

)

SELECT *
FROM source_data
