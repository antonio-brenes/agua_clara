{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'dimension']
) }}

with dates as (
    select DATA_INI_FACT as FECHA from {{ ref('s_factura') }} where DATA_INI_FACT is not null
    union
    select DATA_FIN_FACT from {{ ref('s_factura') }} where DATA_FIN_FACT is not null
    union
    select DATA_EMISS_FACT from {{ ref('s_factura') }} where DATA_EMISS_FACT is not null
    union
    select DATA_CARREC_RECAP from {{ ref('s_factura') }} where DATA_CARREC_RECAP is not null
    union
    select MOM_INI_SITUACION::date from {{ ref('s_factura_situacion_hist') }} where MOM_INI_SITUACION is not null
    union
    select MOM_FIN_SITUACION::date from {{ ref('s_factura_situacion_hist') }} where MOM_FIN_SITUACION is not null
    union
    select DATA_FIN_PER_INCID from {{ ref('s_factura_regul') }} where DATA_FIN_PER_INCID is not null
    union
    select DATA_INI_IND from {{ ref('edw_s_hist_ss_pe') }} where DATA_INI_IND is not null
    union
    select DATA_FIN_IND from {{ ref('edw_s_hist_ss_pe') }} where DATA_FIN_IND is not null
    union
    select DATA_CREA_C_FRA from {{ ref('edw_s_conveni_frau') }} where DATA_CREA_C_FRA is not null
)

select
    FECHA,
    year(FECHA) as ANYO,
    month(FECHA) as MES,
    monthname(FECHA) as NOMBRE_MES,
    quarter(FECHA) as TRIMESTRE,
    day(FECHA) as DIA,
    dayofweekiso(FECHA) as DIA_SEMANA,
    dayname(FECHA) as NOMBRE_DIA,
    iff(dayofweekiso(FECHA) between 1 and 5, true, false) as ES_LABORABLE
from dates
where FECHA is not null
