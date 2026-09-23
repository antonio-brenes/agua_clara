{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with calendario as (
    select dateadd(day, seq4(), '2020-01-01'::date) as FECHA
    from table(generator(rowcount => 2557))
)
select
    FECHA,
    year(FECHA) as ANYO,
    month(FECHA) as MES,
    lpad(month(FECHA)::varchar, 2, '0') as MES_NUMERO,
    monthname(FECHA) as NOMBRE_MES,
    year(FECHA)::varchar || lpad(month(FECHA)::varchar, 2, '0') as ANYO_MES,
    lpad(month(FECHA)::varchar, 2, '0') || '/' || year(FECHA)::varchar as MES_ANYO,
    quarter(FECHA) as TRIMESTRE,
    day(FECHA) as DIA,
    dayofweekiso(FECHA) as DIA_SEMANA,
    dayname(FECHA) as NOMBRE_DIA,
    weekiso(FECHA) as SEMANA_ISO,
    yearofweekiso(FECHA)::varchar || lpad(weekiso(FECHA)::varchar, 2, '0') as ANYO_SEMANA,
    dayofyear(FECHA) as DIA_ANYO,
    iff(dayofweekiso(FECHA) in (6,7), true, false) as ES_FIN_SEMANA,
    iff(dayofweekiso(FECHA) in (6,7), false, true) as ES_LABORABLE,
    date_trunc('month', FECHA)::date as INICIO_MES,
    last_day(FECHA, 'month')::date as FIN_MES,
    date_trunc('quarter', FECHA)::date as INICIO_TRIMESTRE,
    last_day(FECHA, 'quarter')::date as FIN_TRIMESTRE,
    0::number as ID_CARGA,
    null::timestamp_tz as FECHA_EXTRACCION,
    convert_timezone('Europe/Madrid', current_timestamp()) as FECHA_CARGA,
    'GOLD' as SISTEMA_ORIGEN,
    'CALENDARIO_GENERADO' as TABLA_ORIGEN
from calendario
where FECHA <= '2026-12-31'::date
