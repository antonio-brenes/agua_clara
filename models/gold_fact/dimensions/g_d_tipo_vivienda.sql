{{ config(materialized='table', schema='gold_fact', tags=['gold_fact', 'dimension']) }}
with catalogo as (
    select *
    from {{ ref('edw_s_tipo_vivienda') }}
    qualify row_number() over (
        partition by HK_TIPO_VIVIENDA
        order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc
    ) = 1
)
select
    HK_TIPO_VIVIENDA, COD_TIPO_VIVIENDA, DES_TIPO_VIVIENDA, DES_ABREV_TIPO_VIVIENDA,
    ID_CARGA, FECHA_EXTRACCION,
    convert_timezone('Europe/Madrid', current_timestamp()) as FECHA_CARGA,
    SISTEMA_ORIGEN, 'EDW_S_TIPO_VIVIENDA' as TABLA_ORIGEN
from catalogo
union all
select
    sha2_hex('DESCONOCIDO', 256), '?', 'Desconocido', 'Desconocido',
    -1, null, convert_timezone('Europe/Madrid', current_timestamp()),
    'GOLD_FACT', 'G_D_TIPO_VIVIENDA'
