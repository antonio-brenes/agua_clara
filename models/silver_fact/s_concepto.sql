{{ config(
    materialized='table',
    schema='silver_fact',
    tags=['silver_fact', 'maestro', 'facturacion']
) }}

select
    SHA2_HEX(UPPER(TRIM(CLAU_CODI)), 256) as HK_CONCEPTO,
    CLAU_CODI as NUM_CONCEPTE,
    DESC_CODI as DESC_CONCEPTE,
    DESC_BREU as DESC_BREU_CONCEPTE,
    ID_CARGA,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'L4_CODIFICACIONS' as TABLA_ORIGEN
from {{ ref('l4_codificacions') }}
where TIP_CODI = 'F25'
