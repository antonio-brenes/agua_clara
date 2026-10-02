{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with clientes as (
    select
        sha2_hex(upper(trim(DNI_NIF_CLIENT)), 256) as HK_CLIENTE,
        DNI_NIF_CLIENT,
        NOM_CLIENT,
        NOM_COMERCIAL,
        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN,
        row_number() over (partition by DNI_NIF_CLIENT order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc) as RN
    from {{ ref('edw_s_submin_servei') }}
    where nullif(trim(DNI_NIF_CLIENT), '') is not null
)
select
    HK_CLIENTE,
    DNI_NIF_CLIENT,
    NOM_CLIENT,
    NOM_COMERCIAL,
    ID_CARGA,
    FECHA_EXTRACCION,
    convert_timezone('Europe/Madrid', current_timestamp()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'EDW_S_SUBMIN_SERVEI' as TABLA_ORIGEN
from clientes
where RN = 1
union all
select
    sha2_hex('DESCONOCIDO', 256),
    'DESCONOCIDO',
    'Desconocido',
    null,
    -1,
    null,
    convert_timezone('Europe/Madrid', current_timestamp()),
    'GOLD',
    'EDW_S_SUBMIN_SERVEI'
