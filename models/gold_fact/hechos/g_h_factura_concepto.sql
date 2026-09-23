{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_CONCEPTE',
    schema='gold_fact',
    tags=['gold_fact', 'fact']
) }}

select
    c.HK_FACTURA_CONCEPTE,
    c.HK_FACTURA,
    c.HK_SUBMIN_SERVEI,
    case
        when c.TABLA_ORIGEN = 'L4_FACT_AIGUA' then 'TIPUS:' || c.TIPUS_CONCEPTE
        else 'CONCEPTE:' || c.NUM_CONCEPTE
    end as CODIGO_CONCEPTO,
    c.ID_EMPRESA,
    c.ANY_FACTURA,
    c.NUM_FACTURA,
    c.NUM_PARTICIO,
    c.NUM_LINEA,
    c.TIPUS_CONCEPTE,
    c.NUM_CONCEPTE,
    c.DESC_CONCEPTE,
    c.POLISSA_SUBM,
    c.DATA_INI_FACT,
    c.DATA_FIN_FACT,
    c.DATA_EMISS_FACT,
    c.TIP_SUBM_SERV,
    c.QUANTITAT,
    c.UNITAT_MESURA,
    c.BASE_CALCUL,
    c.TIP_TAXA,
    c.PREU_UNITARI,
    c.PERCENTATGE,
    c.IMP_CONCEPTE,
    c.IVA_APLICAT,
    c.ID_CARGA,
    c.FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    c.SISTEMA_ORIGEN,
    c.TABLA_ORIGEN
from {{ ref('s_factura_concepto') }} c
