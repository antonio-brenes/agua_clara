{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_SITUACION',
    schema='silver_fact',
    tags=['silver_fact', 'facturacion']
) }}

WITH situaciones AS (

    SELECT
        s.*,
        LEAD(s.MOM_SIT_FACT) OVER (
            PARTITION BY
                s.NUM_PARTICIO,
                s.ID_EMPRESA,
                s.ANY_FACTURA,
                s.NUM_FACTURA
            ORDER BY s.MOM_SIT_FACT
        ) AS MOM_FIN_SITUACION,

        ROW_NUMBER() OVER (
            PARTITION BY
                s.NUM_PARTICIO,
                s.ID_EMPRESA,
                s.ANY_FACTURA,
                s.NUM_FACTURA
            ORDER BY s.MOM_SIT_FACT
        ) AS NUM_ORDEN_SITUACION,

        ROW_NUMBER() OVER (
            PARTITION BY
                s.NUM_PARTICIO,
                s.ID_EMPRESA,
                s.ANY_FACTURA,
                s.NUM_FACTURA
            ORDER BY s.MOM_SIT_FACT DESC
        ) AS RN_ULTIMA

    FROM {{ ref('l4_situacio_fact') }} AS s

),

catalogo_estado AS (

    SELECT
        TIP_SIT_FACT,
        DESC_SITUACION,
        DESC_BREU_SITUACION

    FROM {{ ref('s_situacion_factura') }}

)

SELECT
    SHA2_HEX(
        CONCAT_WS(
            '|',
            TO_VARCHAR(s.NUM_PARTICIO),
            UPPER(TRIM(s.ID_EMPRESA)),
            UPPER(TRIM(s.ANY_FACTURA)),
            TO_VARCHAR(s.NUM_FACTURA),
            TO_VARCHAR(s.MOM_SIT_FACT, 'YYYY-MM-DD HH24:MI:SS.FF9')
        ),
        256
    ) AS HK_FACTURA_SITUACION,

    SHA2_HEX(
        UPPER(TRIM(s.TIP_SIT_FACT)),
        256
    ) AS HK_SITUACION_FACT,

    SHA2_HEX(
        CONCAT_WS(
            '|',
            TO_VARCHAR(s.NUM_PARTICIO),
            UPPER(TRIM(s.ID_EMPRESA)),
            UPPER(TRIM(s.ANY_FACTURA)),
            TO_VARCHAR(s.NUM_FACTURA)
        ),
        256
    ) AS HK_FACTURA,

    s.NUM_PARTICIO,
    s.ID_EMPRESA,
    s.ANY_FACTURA,
    s.NUM_FACTURA,

    s.MOM_SIT_FACT AS MOM_INI_SITUACION,
    s.MOM_FIN_SITUACION,
    s.NUM_ORDEN_SITUACION,
    IFF(s.RN_ULTIMA = 1, TRUE, FALSE) AS ES_SITUACION_ACTUAL,

    s.TIP_SIT_FACT,
    cat.DESC_SITUACION,
    cat.DESC_BREU_SITUACION,
    s.CAUSA_SIT_FACT,

    s.ID_CARGA,
    s.FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    s.SISTEMA_ORIGEN,
    'L4_SITUACIO_FACT' AS TABLA_ORIGEN

FROM situaciones AS s
LEFT JOIN catalogo_estado AS cat
    ON cat.TIP_SIT_FACT = s.TIP_SIT_FACT

WHERE s.NUM_PARTICIO IS NOT NULL
  AND NULLIF(TRIM(s.ID_EMPRESA), '') IS NOT NULL
  AND NULLIF(TRIM(s.ANY_FACTURA), '') IS NOT NULL
  AND s.NUM_FACTURA IS NOT NULL
  AND s.MOM_SIT_FACT IS NOT NULL
