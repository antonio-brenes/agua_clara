{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'dimension']
) }}

select
    HK_SITUACION_FACT,
    TIP_SIT_FACT,
    DESC_SITUACION,
    DESC_BREU_SITUACION,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'S_SITUACION_FACTURA' as TABLA_ORIGEN
from {{ ref('s_situacion_factura') }}
