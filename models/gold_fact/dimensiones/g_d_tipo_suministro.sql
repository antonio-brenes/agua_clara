{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'dimension']
) }}

select
    HK_TIPO_SUMINISTRO,
    COD_TIPO_SUMINISTRO,
    DES_TIPO_SUMINISTRO,
    DES_ABREV_TIPO_SUMINISTRO,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'EDW_S_TIPO_SUMINISTRO' as TABLA_ORIGEN
from {{ ref('edw_s_tipo_suministro') }}
qualify row_number() over (
    partition by HK_TIPO_SUMINISTRO
    order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc
) = 1
