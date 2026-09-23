{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with clientes as (
    select
        sha2_hex('CLIENTE|' || upper(trim(DNI_NIF_CLIENT)), 256) as HK_CLIENTE,
        DNI_NIF_CLIENT,
        NOM_CLIENT,
        NOM_CLIENT as NOM_TITULAR,
        cast(null as varchar) as NOM_COMERCIAL,
        ID_CARGA, FECHA_EXTRACCION, SISTEMA_ORIGEN,
        row_number() over (partition by DNI_NIF_CLIENT order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc) as RN
    from {{ ref('s_factura') }}
    where nullif(trim(DNI_NIF_CLIENT), '') is not null
)
select HK_CLIENTE, DNI_NIF_CLIENT, NOM_CLIENT, NOM_TITULAR, NOM_COMERCIAL,
       ID_CARGA, FECHA_EXTRACCION,
       convert_timezone('Europe/Madrid', current_timestamp()) as FECHA_CARGA,
       SISTEMA_ORIGEN, 'S_FACTURA' as TABLA_ORIGEN
from clientes where RN=1
union all
select sha2_hex('CLIENTE|DESCONOCIDO',256), 'DESCONOCIDO','Desconocido','Desconocido',null,
       0,null,convert_timezone('Europe/Madrid',current_timestamp()),'GOLD','S_FACTURA'
