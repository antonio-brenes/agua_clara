{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='HK_FACTURA_SITUACION',
    schema='gold_fact',
    tags=['gold_fact', 'fact']
) }}

select
    HK_FACTURA_SITUACION,
    HK_FACTURA,
    HK_SITUACION_FACT,
    ID_EMPRESA,
    ANY_FACTURA,
    NUM_FACTURA,
    NUM_PARTICIO,
    MOM_INI_SITUACION,
    MOM_FIN_SITUACION,
    NUM_ORDEN_SITUACION,
    ES_SITUACION_ACTUAL,
    TIP_SIT_FACT,
    DESC_SITUACION,
    DESC_BREU_SITUACION,
    CAUSA_SIT_FACT,
    ID_CARGA,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'S_FACTURA_SITUACION_HIST' as TABLA_ORIGEN
from {{ ref('s_factura_situacion_hist') }}
