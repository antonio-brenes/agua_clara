{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_REGUL',
    schema='gold_fact',
    tags=['gold_fact', 'fact']
) }}

select
    r.HK_FACTURA_REGUL,
    r.HK_FACTURA,
    f.HK_SUBMIN_SERVEI,
    r.ID_EMPRESA,
    r.ANY_FACTURA,
    r.NUM_FACTURA,
    r.NUM_PARTICIO,
    r.DATA_FIN_PER_INCID,
    r.M3_TOTAL_REGULARIZADOS,
    r.IMP_TOTAL_REGULARIZACION,
    r.IMP_BLOC1_RG,
    r.IMP_BLOC2_RG,
    r.IMP_BLOC3_RG,
    r.IMP_BLOC4_RG,
    r.IMP_BLOC5_RG,
    r.IMP_CT_XBASICA_RG,
    r.IMP_TCG_SUBM_RG,
    r.IMP_CTG_SUBM_RG,
    r.IMP_CAN_BAELLS_RG,
    r.IMP_CAN_TER_RG,
    r.IMP_PRODUC_BRUT_RG,
    r.IMP_CLAVAG_RG,
    r.IMP_SANEJA_RG,
    r.IMP_ERSU_RG,
    r.IMP_CIH_BLOC1_RG,
    r.IMP_CIH_BLOC2_RG,
    r.IMP_CIH_BLOC3_RG,
    r.IMP_CAI_T1_RG,
    r.IMP_CAI_T2_RG,
    r.IMP_CLA_T2_RG,
    r.IMP_CAI_T3_RG,
    r.IMP_CAI_T4_RG,
    r.ID_CARGA,
    r.FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    r.SISTEMA_ORIGEN,
    'S_FACTURA_REGUL' as TABLA_ORIGEN
from {{ ref('s_factura_regul') }} r
inner join {{ ref('s_factura') }} f
    on f.HK_FACTURA = r.HK_FACTURA
