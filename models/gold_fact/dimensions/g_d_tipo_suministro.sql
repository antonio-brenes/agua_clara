{{ config(materialized='table', schema='gold_fact', tags=['gold_fact', 'dimension']) }}
select
    HK_TIPO_SUMINISTRO,
    COD_TIPO_SUMINISTRO,
    DES_TIPO_SUMINISTRO,
    DES_ABREV_TIPO_SUMINISTRO,
    ID_CARGA,
    FECHA_EXTRACCION,
    convert_timezone('Europe/Madrid', current_timestamp()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'EDW_S_TIPO_SUMINISTRO' as TABLA_ORIGEN
from {{ ref('edw_s_tipo_suministro') }}
qualify
    row_number()
        over (
            partition by HK_TIPO_SUMINISTRO
            order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc
        )
    = 1
union all
select
    sha2_hex('DESCONOCIDO', 256),
    '?',
    'Desconocido',
    'Desconocido',
    -1,
    null,
    convert_timezone('Europe/Madrid', current_timestamp()),
    'GOLD_FACT',
    'G_D_TIPO_SUMINISTRO'
