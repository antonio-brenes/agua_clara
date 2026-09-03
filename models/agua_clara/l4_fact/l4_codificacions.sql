{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}

with raw as (
    select *
    from (select 1 as placeholder where false)
)

select
    CAST(NULL AS VARCHAR(3)) AS TIP_CODI,
    CAST(NULL AS VARCHAR(5)) AS CLAU_CODI,
    CAST(NULL AS VARCHAR(50)) AS DESC_CODI,
    CAST(NULL AS VARCHAR(20)) AS DESC_BREU,
    DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA,
    CAST(NULL AS TIMESTAMP_NTZ) AS FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA,
    CAST(NULL AS VARCHAR(30)) AS SISTEMA_ORIGEN,
    'RAW_CODIFICACIONS' AS TABLA_ORIGEN
from raw
