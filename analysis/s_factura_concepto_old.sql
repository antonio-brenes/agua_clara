{% set query -%}
    select * from {{ ref('s_tip_conceptos_agua') -}} 
{%- endset -%}

{%- set tip_conceptos_agua=run_query(query).rows -%}

WITH factura AS (

    SELECT
        NUM_PARTICIO,
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        POLISSA_SUBM,
        DATA_INI_FACT,
        DATA_FIN_FACT,
        DATA_EMISS_FACT,
        TIP_SUBM_SERV AS COD_TIPO_SUMINISTRO_FACTURA,
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
        a.NUM_PARTICIO,
        f.ID_EMPRESA,
        f.ANY_FACTURA,
        f.NUM_FACTURA,
        f.POLISSA_SUBM,
        f.DATA_INI_FACT,
        f.DATA_FIN_FACT,
        f.DATA_EMISS_FACT,
        f.COD_TIPO_SUMINISTRO_FACTURA,

        conc.value:ORDEN::NUMBER(3,0) AS NUM_LINEA,
        conc.value:NUM_CONCEPTO::VARCHAR AS NUM_CONCEPTO,
        conc.value:DESC_CONCEPTO::VARCHAR AS DESC_CONCEPTO,
        conc.value:CANTIDAD::NUMBER(18,6) AS CANTIDAD,
        conc.value:UNIDAD_MEDIDA::VARCHAR AS UNIDAD_MEDIDA,
        conc.value:BASE_CALCULO::NUMBER(18,6) AS BASE_CALCULO,
        conc.value:TIPO_TASA::VARCHAR AS TIPO_TASA,
        conc.value:PRECIO_UNITARIO::NUMBER(18,6) AS PRECIO_UNITARIO,
        conc.value:PORCENTAJE::NUMBER(9,4) AS PORCENTAJE,
        conc.value:IMP_CONCEPTO::NUMBER(18,2) AS IMP_CONCEPTO,
        conc.value:IVA_APLICADO::NUMBER(9,4) AS IVA_APLICADO,

        a.ID_CARGA,
        a.FECHA_EXTRACCION,
        a.SISTEMA_ORIGEN,
        'L4_FACT_AIGUA' AS TABLA_ORIGEN

    FROM factura AS f

    INNER JOIN linea_agua AS a
        ON f.NUM_PARTICIO = a.NUM_PARTICIO
       AND f.ID_EMPRESA = a.ID_EMPRESA
       AND f.ANY_FACTURA = a.ANY_FACTURA
       AND f.NUM_FACTURA = a.NUM_FACTURA

    CROSS JOIN LATERAL FLATTEN(
        INPUT => ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 1,
                'NUM_CONCEPTO', 'A001',
                'DESC_CONCEPTO', 'Consum d''aigua bloc 1',
                'CANTIDAD', f.M3_BLOC1,
                'UNIDAD_MEDIDA', 'M3',
                'BASE_CALCULO', f.M3_BLOC1,
                'TIPO_TASA', 'UNITARI',
                'PRECIO_UNITARIO', a.PREU_M3_BLOC1_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_BLOC1,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 2,
                'NUM_CONCEPTO', 'A002',
                'DESC_CONCEPTO', 'Consum d''aigua bloc 2',
                'CANTIDAD', f.M3_BLOC2,
                'UNIDAD_MEDIDA', 'M3',
                'BASE_CALCULO', f.M3_BLOC2,
                'TIPO_TASA', 'UNITARI',
                'PRECIO_UNITARIO', a.PREU_M3_BLOC2_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_BLOC2,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 3,
                'NUM_CONCEPTO', 'A003',
                'DESC_CONCEPTO', 'Consum d''aigua bloc 3',
                'CANTIDAD', f.M3_BLOC3,
                'UNIDAD_MEDIDA', 'M3',
                'BASE_CALCULO', f.M3_BLOC3,
                'TIPO_TASA', 'UNITARI',
                'PRECIO_UNITARIO', a.PREU_M3_BLOC3_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_BLOC3,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 4,
                'NUM_CONCEPTO', 'A004',
                'DESC_CONCEPTO', 'Consum d''aigua bloc 4',
                'CANTIDAD', f.M3_BLOC4,
                'UNIDAD_MEDIDA', 'M3',
                'BASE_CALCULO', f.M3_BLOC4,
                'TIPO_TASA', 'UNITARI',
                'PRECIO_UNITARIO', a.PREU_M3_BLOC4_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_BLOC4,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 5,
                'NUM_CONCEPTO', 'A005',
                'DESC_CONCEPTO', 'Consum d''aigua bloc 5',
                'CANTIDAD', f.M3_BLOC5,
                'UNIDAD_MEDIDA', 'M3',
                'BASE_CALCULO', f.M3_BLOC5,
                'TIPO_TASA', 'UNITARI',
                'PRECIO_UNITARIO', a.PREU_M3_BLOC5_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_BLOC5,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 10,
                'NUM_CONCEPTO', 'A010',
                'DESC_CONCEPTO', 'Quota de servei',
                'CANTIDAD', 1,
                'UNIDAD_MEDIDA', 'FACTURA',
                'BASE_CALCULO', 1,
                'TIPO_TASA', 'UNITARI',
                'PRECIO_UNITARIO', a.IMP_QTA_SERV,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_QTA_SERV,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 20,
                'NUM_CONCEPTO', 'A011',
                'DESC_CONCEPTO', 'Quota o cànon de tarifa bàsica',
                'CANTIDAD', a.BASE_CT_XBASICA,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_CT_XBASICA,
                'TIPO_TASA', a.TIP_CT_XBASICA_FAC,
                'PRECIO_UNITARIO', a.PREU_CT_XBASICA_FA,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_CT_XBASICA,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 21,
                'NUM_CONCEPTO', 'A012',
                'DESC_CONCEPTO', 'Tarifa o cànon general del subministrament',
                'CANTIDAD', a.BASE_TCG_SUBM,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_TCG_SUBM,
                'TIPO_TASA', a.TIP_TCG_SUBM_FACT,
                'PRECIO_UNITARIO', a.PREU_TCG_SUBM_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_TCG_SUBM,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 30,
                'NUM_CONCEPTO', 'A020',
                'DESC_CONCEPTO', 'Clavegueram',
                'CANTIDAD', a.BASE_CLAVAG,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_CLAVAG,
                'TIPO_TASA', a.TIP_CLAVAG_FACT,
                'PRECIO_UNITARIO', a.PREU_CLAVAG_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_CLAVAG,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 31,
                'NUM_CONCEPTO', 'A021',
                'DESC_CONCEPTO', 'Sanejament',
                'CANTIDAD', a.BASE_SANEJA,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_SANEJA,
                'TIPO_TASA', a.TIP_SANEJA_FACT,
                'PRECIO_UNITARIO', a.PREU_SANEJA_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_SANEJA,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 32,
                'NUM_CONCEPTO', 'A022',
                'DESC_CONCEPTO', 'Residus urbans',
                'CANTIDAD', a.BASE_ERSU,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_ERSU,
                'TIPO_TASA', a.TIP_ERSU_FACT,
                'PRECIO_UNITARIO', a.PREU_ERSU_FACT,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_ERSU,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 40,
                'NUM_CONCEPTO', 'C001',
                'DESC_CONCEPTO', 'Cànon d''infraestructura hidràulica bloc 1',
                'CANTIDAD', a.BASE_CIH_BLOC1,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_CIH_BLOC1,
                'TIPO_TASA', a.TIP_CIH_FACT,
                'PRECIO_UNITARIO', a.PREU_CIH_BLOC1_FA,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_CIH_BLOC1,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 41,
                'NUM_CONCEPTO', 'C002',
                'DESC_CONCEPTO', 'Cànon d''infraestructura hidràulica bloc 2',
                'CANTIDAD', a.BASE_CIH_BLOC2,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_CIH_BLOC2,
                'TIPO_TASA', a.TIP_CIH_FACT,
                'PRECIO_UNITARIO', a.PREU_CIH_BLOC2_FA,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_CIH_BLOC2,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 42,
                'NUM_CONCEPTO', 'C003',
                'DESC_CONCEPTO', 'Cànon d''infraestructura hidràulica bloc 3',
                'CANTIDAD', a.BASE_CIH_BLOC3,
                'UNIDAD_MEDIDA', 'BASE',
                'BASE_CALCULO', a.BASE_CIH_BLOC3,
                'TIPO_TASA', a.TIP_CIH_FACT,
                'PRECIO_UNITARIO', a.PREU_CIH_BLOC3_FA,
                'PORCENTAJE', NULL,
                'IMP_CONCEPTO', a.IMP_CIH_BLOC3,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 90,
                'NUM_CONCEPTO', 'I001',
                'DESC_CONCEPTO', 'IVA de sanejament',
                'CANTIDAD', NULL,
                'UNIDAD_MEDIDA', 'PERCENT',
                'BASE_CALCULO', a.BASE_IVA_SANEJA,
                'TIPO_TASA', 'PERCENT',
                'PRECIO_UNITARIO', NULL,
                'PORCENTAJE', a.PERCENT_IVA_FACT,
                'IMP_CONCEPTO', a.IMP_IVA_SANEJA,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            ),
            OBJECT_CONSTRUCT_KEEP_NULL(
                'ORDEN', 91,
                'NUM_CONCEPTO', 'I002',
                'DESC_CONCEPTO', 'IVA del aigua',
                'CANTIDAD', NULL,
                'UNIDAD_MEDIDA', 'PERCENT',
                'BASE_CALCULO', a.BASE_IVA,
                'TIPO_TASA', 'PERCENT',
                'PRECIO_UNITARIO', NULL,
                'PORCENTAJE', a.PERCENT_IVA_FACT,
                'IMP_CONCEPTO', a.IMP_IVA,
                'IVA_APLICADO', a.PERCENT_IVA_FACT
            )
        )
    ) AS conc

),

conceptos_agua_distintos_cero AS (

    SELECT *
    FROM conceptos_agua
    WHERE COALESCE(CANTIDAD, 0) <> 0
       OR COALESCE(BASE_CALCULO, 0) <> 0
       OR COALESCE(IMP_CONCEPTO, 0) <> 0

),

conceptos_resto AS (

    SELECT
        c.NUM_PARTICIO,
        c.ID_EMPRESA,
        c.ANY_FACTURA,
        c.NUM_FACTURA,
        f.POLISSA_SUBM,
        f.DATA_INI_FACT,
        f.DATA_FIN_FACT,
        f.DATA_EMISS_FACT,
        f.COD_TIPO_SUMINISTRO_FACTURA,

        c.NUM_LINEA,
        c.NUM_CONCEPTE AS NUM_CONCEPTO,
        COALESCE(c.OBSER_CONCEPTE, c.NUM_CONCEPTE) AS DESC_CONCEPTO,
        c.BASE_CONCEPTE AS CANTIDAD,
        CASE
            WHEN UPPER(TRIM(c.TIP_TAXA_CONCEP)) = 'PERCENT' THEN 'PERCENT'
            ELSE 'UNITAT'
        END AS UNIDAD_MEDIDA,
        c.BASE_CONCEPTE AS BASE_CALCULO,
        c.TIP_TAXA_CONCEP AS TIPO_TASA,
        CASE
            WHEN UPPER(TRIM(c.TIP_TAXA_CONCEP)) = 'PERCENT' THEN NULL
            ELSE c.PREU_CONCEPTE
        END AS PRECIO_UNITARIO,
        CASE
            WHEN UPPER(TRIM(c.TIP_TAXA_CONCEP)) = 'PERCENT' THEN c.PREU_CONCEPTE
            ELSE NULL
        END AS PORCENTAJE,
        c.IMP_CONCEPTE AS IMP_CONCEPTO,
        c.IVA_APLICAT_CONC AS IVA_APLICADO,

        c.ID_CARGA,
        c.FECHA_EXTRACCION,
        c.SISTEMA_ORIGEN,
        'L4_FACT_CONCEPTE' AS TABLA_ORIGEN

    FROM concepto AS c

    INNER JOIN factura AS f
        ON f.NUM_PARTICIO = c.NUM_PARTICIO
       AND f.ID_EMPRESA = c.ID_EMPRESA
       AND f.ANY_FACTURA = c.ANY_FACTURA
       AND f.NUM_FACTURA = c.NUM_FACTURA

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
            TO_VARCHAR(NUM_PARTICIO),
            UPPER(TRIM(ID_EMPRESA)),
            UPPER(TRIM(ANY_FACTURA)),
            TO_VARCHAR(NUM_FACTURA),
            TO_VARCHAR(NUM_LINEA),
            COALESCE(UPPER(TRIM(NUM_CONCEPTO)), '^^')
        ),
        256
    ) AS HK_FACTURA_CONCEPTO,

    SHA2_HEX(
        CONCAT_WS(
            '|',
            TO_VARCHAR(NUM_PARTICIO),
            UPPER(TRIM(ID_EMPRESA)),
            UPPER(TRIM(ANY_FACTURA)),
            TO_VARCHAR(NUM_FACTURA)
        ),
        256
    ) AS HK_FACTURA,

    SHA2_HEX(
        UPPER(TRIM(NUM_CONCEPTO)),
        256
    ) AS HK_CONCEPTO,    

    SHA2_HEX(
        UPPER(TRIM(POLISSA_SUBM)),
        256
    ) AS HK_SUBMIN_SERVEI,

    SHA2_HEX(UPPER(TRIM(COD_TIPO_SUMINISTRO_FACTURA)), 256)
        AS HK_TIPO_SUMINISTRO,

    NUM_PARTICIO,
    ID_EMPRESA,
    ANY_FACTURA,
    NUM_FACTURA,
    NUM_LINEA,
    NUM_CONCEPTO,
    DESC_CONCEPTO,

    POLISSA_SUBM,
    DATA_INI_FACT,
    DATA_FIN_FACT,
    DATA_EMISS_FACT,
    COD_TIPO_SUMINISTRO_FACTURA,

    CANTIDAD,
    UNIDAD_MEDIDA,
    BASE_CALCULO,
    TIPO_TASA,
    PRECIO_UNITARIO,
    PORCENTAJE,
    IMP_CONCEPTO,
    IVA_APLICADO,

    ID_CARGA,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA,
    SISTEMA_ORIGEN,
    TABLA_ORIGEN

FROM conceptos
