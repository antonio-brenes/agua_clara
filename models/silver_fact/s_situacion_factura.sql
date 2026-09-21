{{ config(
    materialized='table',
    schema='silver_fact',
    tags=['silver_fact', 'maestro', 'facturacion']
) }}

select
    SHA2_HEX(UPPER(TRIM(CLAU_CODI)), 256) as HK_SITUACION_FACT,
    CLAU_CODI as TIP_SIT_FACT,
    DESC_CODI as DESC_SITUACION,
    DESC_BREU as DESC_BREU_SITUACION,
    ID_CARGA,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'L4_CODIFICACIONS' as TABLA_ORIGEN
from {{ ref('l4_codificacions') }}
where TIP_CODI = 'R01'
