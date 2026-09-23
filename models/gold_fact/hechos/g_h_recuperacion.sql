{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_RECUP',
    schema='gold_fact',
    tags=['gold_fact', 'fact']
) }}

select
    r.HK_FACTURA_RECUP,
    r.HK_FACTURA,
    f.HK_SUBMIN_SERVEI,
    r.ID_EMPRESA,
    r.ANY_FACTURA,
    r.NUM_FACTURA,
    r.NUM_PARTICIO,
    r.M3_TOTAL_RECUPERADOS,
    r.IMP_TOTAL_RECUPERACION,
    r.IMP_QTA_SERV_RC,
    r.IMP_BLOC1_RC,
    r.IMP_BLOC2_RC,
    r.IMP_BLOC3_RC,
    r.IMP_CT_XBASICA_RC,
    r.IMP_TCG_SUBM_RC,
    r.IMP_CLAVAG_RC,
    r.IMP_SANEJA_RC,
    r.IMP_ERSU_RC,
    r.IMP_CIH_BLOC1_RC,
    r.IMP_CIH_BLOC2_RC,
    r.IMP_CIH_BLOC3_RC,
    r.IMP_BONIF_QTA_RC,
    r.IMP_CAI_T1_RC,
    r.IMP_CAI_T2_RC,
    r.IMP_CLA_T2_RC,
    r.IMP_CAI_T3_RC,
    r.ID_CARGA,
    r.FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    r.SISTEMA_ORIGEN,
    'S_FACTURA_RECUP' as TABLA_ORIGEN
from {{ ref('s_factura_recup') }} r
inner join {{ ref('s_factura') }} f
    on f.HK_FACTURA = r.HK_FACTURA
