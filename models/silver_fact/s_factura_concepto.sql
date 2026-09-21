{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_CONCEPTE',
    schema='silver_fact',
    tags=['silver_fact', 'facturacion']
) }}

-- depends_on: {{ ref('edw_h_submin_servei') }}
-- depends_on: {{ ref('edw_h_tipo_suministro') }}

WITH factura AS (

    SELECT
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        POLISSA_SUBM,
        DATA_INI_FACT,
        DATA_FIN_FACT,
        DATA_EMISS_FACT,
        TIP_SUBM_SERV,
        M3_BLOC1,
        M3_BLOC2,
        M3_BLOC3,
        M3_BLOC4,
        M3_BLOC5
    FROM {{ ref('l4_fact_resum') }}

),

linea_agua AS (

    SELECT *
    FROM {{ ref('l4_fact_aigua') }}

),

concepto AS (

    SELECT *
    FROM {{ ref('l4_fact_concepte') }}

),

/*
   Convierte la fila ancha de L4_FACT_AIGUA en conceptos económicos.
   Los conceptos con cantidad, base e importe todos nulos o cero se eliminan después.
*/
conceptos_agua AS (

    SELECT
        f.ID_EMPRESA,
        f.ANY_FACTURA,
        f.NUM_FACTURA,
        a.NUM_PARTICIO,
        f.POLISSA_SUBM,
        f.DATA_INI_FACT,
        f.DATA_FIN_FACT,
        f.DATA_EMISS_FACT,
        f.TIP_SUBM_SERV,

        conc.value:ORDEN::NUMBER(3,0) AS NUM_LINEA,
        conc.value:TIPUS_CONCEPTE::VARCHAR AS TIPUS_CONCEPTE,
        conc.value:NUM_CONCEPTE::VARCHAR AS NUM_CONCEPTE,
        conc.value:DESC_CONCEPTE::VARCHAR AS DESC_CONCEPTE,
        conc.value:QUANTITAT::NUMBER(18,6) AS QUANTITAT,
        conc.value:UNITAT_MESURA::VARCHAR AS UNITAT_MESURA,
        conc.value:BASE_CALCUL::NUMBER(18,6) AS BASE_CALCUL,
        conc.value:TIP_TAXA::VARCHAR AS TIP_TAXA,
        conc.value:PREU_UNITARI::NUMBER(18,6) AS PREU_UNITARI,
        conc.value:PERCENTATGE::NUMBER(9,4) AS PERCENTATGE,
        conc.value:IMP_CONCEPTE::NUMBER(18,2) AS IMP_CONCEPTE,
        conc.value:IVA_APLICAT::NUMBER(9,4) AS IVA_APLICAT,

        a.ID_CARGA,
        a.FECHA_EXTRACCION,
        a.SISTEMA_ORIGEN,
        'L4_FACT_AIGUA' AS TABLA_ORIGEN

    FROM factura AS f

    INNER JOIN linea_agua AS a
        ON f.ID_EMPRESA = a.ID_EMPRESA
       AND f.ANY_FACTURA = a.ANY_FACTURA
       AND f.NUM_FACTURA = a.NUM_FACTURA
       AND f.NUM_PARTICIO = a.NUM_PARTICIO

    CROSS JOIN LATERAL FLATTEN(
        INPUT => ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 1,
                'TIPUS_CONCEPTE', 'AIGUA_BLOC1',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Consum d''aigua bloc 1',
                'QUANTITAT', f.M3_BLOC1,
                'UNITAT_MESURA', 'M3',
                'BASE_CALCUL', f.M3_BLOC1,
                'TIP_TAXA', 'UNITARI',
                'PREU_UNITARI', a.PREU_M3_BLOC1_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_BLOC1,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 2,
                'TIPUS_CONCEPTE', 'AIGUA_BLOC2',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Consum d''aigua bloc 2',
                'QUANTITAT', f.M3_BLOC2,
                'UNITAT_MESURA', 'M3',
                'BASE_CALCUL', f.M3_BLOC2,
                'TIP_TAXA', 'UNITARI',
                'PREU_UNITARI', a.PREU_M3_BLOC2_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_BLOC2,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 3,
                'TIPUS_CONCEPTE', 'AIGUA_BLOC3',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Consum d''aigua bloc 3',
                'QUANTITAT', f.M3_BLOC3,
                'UNITAT_MESURA', 'M3',
                'BASE_CALCUL', f.M3_BLOC3,
                'TIP_TAXA', 'UNITARI',
                'PREU_UNITARI', a.PREU_M3_BLOC3_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_BLOC3,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 4,
                'TIPUS_CONCEPTE', 'AIGUA_BLOC4',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Consum d''aigua bloc 4',
                'QUANTITAT', f.M3_BLOC4,
                'UNITAT_MESURA', 'M3',
                'BASE_CALCUL', f.M3_BLOC4,
                'TIP_TAXA', 'UNITARI',
                'PREU_UNITARI', a.PREU_M3_BLOC4_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_BLOC4,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 5,
                'TIPUS_CONCEPTE', 'AIGUA_BLOC5',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Consum d''aigua bloc 5',
                'QUANTITAT', f.M3_BLOC5,
                'UNITAT_MESURA', 'M3',
                'BASE_CALCUL', f.M3_BLOC5,
                'TIP_TAXA', 'UNITARI',
                'PREU_UNITARI', a.PREU_M3_BLOC5_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_BLOC5,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 10,
                'TIPUS_CONCEPTE', 'QUOTA_SERVEI',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Quota de servei',
                'QUANTITAT', 1,
                'UNITAT_MESURA', 'FACTURA',
                'BASE_CALCUL', 1,
                'TIP_TAXA', 'UNITARI',
                'PREU_UNITARI', a.IMP_QTA_SERV,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_QTA_SERV,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 20,
                'TIPUS_CONCEPTE', 'CT_XBASICA',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Quota o cànon de tarifa bàsica',
                'QUANTITAT', a.BASE_CT_XBASICA,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_CT_XBASICA,
                'TIP_TAXA', a.TIP_CT_XBASICA_FAC,
                'PREU_UNITARI', a.PREU_CT_XBASICA_FA,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_CT_XBASICA,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 21,
                'TIPUS_CONCEPTE', 'TCG_SUBM',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Tarifa o cànon general del subministrament',
                'QUANTITAT', a.BASE_TCG_SUBM,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_TCG_SUBM,
                'TIP_TAXA', a.TIP_TCG_SUBM_FACT,
                'PREU_UNITARI', a.PREU_TCG_SUBM_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_TCG_SUBM,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 30,
                'TIPUS_CONCEPTE', 'CLAVEGUERAM',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Clavegueram',
                'QUANTITAT', a.BASE_CLAVAG,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_CLAVAG,
                'TIP_TAXA', a.TIP_CLAVAG_FACT,
                'PREU_UNITARI', a.PREU_CLAVAG_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_CLAVAG,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 31,
                'TIPUS_CONCEPTE', 'SANEJAMENT',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Sanejament',
                'QUANTITAT', a.BASE_SANEJA,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_SANEJA,
                'TIP_TAXA', a.TIP_SANEJA_FACT,
                'PREU_UNITARI', a.PREU_SANEJA_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_SANEJA,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 32,
                'TIPUS_CONCEPTE', 'ERSU',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Residus urbans',
                'QUANTITAT', a.BASE_ERSU,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_ERSU,
                'TIP_TAXA', a.TIP_ERSU_FACT,
                'PREU_UNITARI', a.PREU_ERSU_FACT,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_ERSU,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 40,
                'TIPUS_CONCEPTE', 'CIH_BLOC1',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Cànon d''infraestructura hidràulica bloc 1',
                'QUANTITAT', a.BASE_CIH_BLOC1,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_CIH_BLOC1,
                'TIP_TAXA', a.TIP_CIH_FACT,
                'PREU_UNITARI', a.PREU_CIH_BLOC1_FA,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_CIH_BLOC1,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 41,
                'TIPUS_CONCEPTE', 'CIH_BLOC2',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Cànon d''infraestructura hidràulica bloc 2',
                'QUANTITAT', a.BASE_CIH_BLOC2,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_CIH_BLOC2,
                'TIP_TAXA', a.TIP_CIH_FACT,
                'PREU_UNITARI', a.PREU_CIH_BLOC2_FA,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_CIH_BLOC2,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 42,
                'TIPUS_CONCEPTE', 'CIH_BLOC3',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'Cànon d''infraestructura hidràulica bloc 3',
                'QUANTITAT', a.BASE_CIH_BLOC3,
                'UNITAT_MESURA', 'BASE',
                'BASE_CALCUL', a.BASE_CIH_BLOC3,
                'TIP_TAXA', a.TIP_CIH_FACT,
                'PREU_UNITARI', a.PREU_CIH_BLOC3_FA,
                'PERCENTATGE', NULL,
                'IMP_CONCEPTE', a.IMP_CIH_BLOC3,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 90,
                'TIPUS_CONCEPTE', 'IVA_SANEJAMENT',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'IVA de sanejament',
                'QUANTITAT', NULL,
                'UNITAT_MESURA', 'PERCENT',
                'BASE_CALCUL', a.BASE_IVA_SANEJA,
                'TIP_TAXA', 'PERCENT',
                'PREU_UNITARI', NULL,
                'PERCENTATGE', a.PERCENT_IVA_FACT,
                'IMP_CONCEPTE', a.IMP_IVA_SANEJA,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 91,
                'TIPUS_CONCEPTE', 'IVA',
                'NUM_CONCEPTE', NULL,
                'DESC_CONCEPTE', 'IVA',
                'QUANTITAT', NULL,
                'UNITAT_MESURA', 'PERCENT',
                'BASE_CALCUL', a.BASE_IVA,
                'TIP_TAXA', 'PERCENT',
                'PREU_UNITARI', NULL,
                'PERCENTATGE', a.PERCENT_IVA_FACT,
                'IMP_CONCEPTE', a.IMP_IVA,
                'IVA_APLICAT', a.PERCENT_IVA_FACT
            )
        )
    ) AS conc

),

conceptos_agua_distintos_cero AS (

    SELECT *
    FROM conceptos_agua
    WHERE COALESCE(QUANTITAT, 0) <> 0
       OR COALESCE(BASE_CALCUL, 0) <> 0
       OR COALESCE(IMP_CONCEPTE, 0) <> 0

),

conceptos_resto AS (

    SELECT
        c.ID_EMPRESA,
        c.ANY_FACTURA,
        c.NUM_FACTURA,
        c.NUM_PARTICIO,
        f.POLISSA_SUBM,
        f.DATA_INI_FACT,
        f.DATA_FIN_FACT,
        f.DATA_EMISS_FACT,
        f.TIP_SUBM_SERV,

        c.NUM_LINEA,
        'CONCEPTE' AS TIPUS_CONCEPTE,
        c.NUM_CONCEPTE,
        COALESCE(c.OBSER_CONCEPTE, c.NUM_CONCEPTE) AS DESC_CONCEPTE,
        c.BASE_CONCEPTE AS QUANTITAT,
        CASE
            WHEN UPPER(TRIM(c.TIP_TAXA_CONCEP)) = 'PERCENT' THEN 'PERCENT'
            ELSE 'UNITAT'
        END AS UNITAT_MESURA,
        c.BASE_CONCEPTE AS BASE_CALCUL,
        c.TIP_TAXA_CONCEP AS TIP_TAXA,
        CASE
            WHEN UPPER(TRIM(c.TIP_TAXA_CONCEP)) = 'PERCENT' THEN NULL
            ELSE c.PREU_CONCEPTE
        END AS PREU_UNITARI,
        CASE
            WHEN UPPER(TRIM(c.TIP_TAXA_CONCEP)) = 'PERCENT' THEN c.PREU_CONCEPTE
            ELSE NULL
        END AS PERCENTATGE,
        c.IMP_CONCEPTE AS IMP_CONCEPTE,
        c.IVA_APLICAT_CONC AS IVA_APLICAT,

        c.ID_CARGA,
        c.FECHA_EXTRACCION,
        c.SISTEMA_ORIGEN,
        'L4_FACT_CONCEPTE' AS TABLA_ORIGEN

    FROM concepto AS c

    INNER JOIN factura AS f
        ON f.ID_EMPRESA = c.ID_EMPRESA
       AND f.ANY_FACTURA = c.ANY_FACTURA
       AND f.NUM_FACTURA = c.NUM_FACTURA
       AND f.NUM_PARTICIO = c.NUM_PARTICIO

),

conceptos AS (

    SELECT * FROM conceptos_agua_distintos_cero
    UNION ALL
    SELECT * FROM conceptos_resto

)

SELECT
    SHA2_HEX(
        CONCAT_WS(
            '|',
            UPPER(TRIM(ID_EMPRESA)),
            UPPER(TRIM(ANY_FACTURA)),
            TO_VARCHAR(NUM_FACTURA),
            TO_VARCHAR(NUM_PARTICIO),
            UPPER(TRIM(TIPUS_CONCEPTE)),
            TO_VARCHAR(NUM_LINEA),
            COALESCE(UPPER(TRIM(NUM_CONCEPTE)), '^^')
        ),
        256
    ) AS HK_FACTURA_CONCEPTE,

    SHA2_HEX(
        CONCAT_WS(
            '|',
            UPPER(TRIM(ID_EMPRESA)),
            UPPER(TRIM(ANY_FACTURA)),
            TO_VARCHAR(NUM_FACTURA)
        ),
        256
    ) AS HK_FACTURA,

    SHA2_HEX(
        UPPER(TRIM(POLISSA_SUBM)),
        256
    ) AS HK_SUBMIN_SERVEI,

    SHA2_HEX(UPPER(TRIM(TIP_SUBM_SERV)), 256)
        AS HK_TIPO_SUMINISTRO,

    ID_EMPRESA,
    ANY_FACTURA,
    NUM_FACTURA,
    NUM_PARTICIO,
    NUM_LINEA,
    TIPUS_CONCEPTE,
    NUM_CONCEPTE,
    DESC_CONCEPTE,

    POLISSA_SUBM,
    DATA_INI_FACT,
    DATA_FIN_FACT,
    DATA_EMISS_FACT,
    TIP_SUBM_SERV,

    QUANTITAT,
    UNITAT_MESURA,
    BASE_CALCUL,
    TIP_TAXA,
    PREU_UNITARI,
    PERCENTATGE,
    IMP_CONCEPTE,
    IVA_APLICAT,

    ID_CARGA,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    SISTEMA_ORIGEN,
    TABLA_ORIGEN

FROM conceptos
