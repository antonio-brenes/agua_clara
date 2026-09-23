{{ config(severity='error', tags=['gold_fact','classification']) }}
with u as (
 select distinct case when TABLA_ORIGEN='L4_FACT_AIGUA' then 'AIGUA:'||TIPUS_CONCEPTE
                      when TABLA_ORIGEN='L4_FACT_CONCEPTE' then 'CONCEPTE:'||NUM_CONCEPTE end CODIGO_CONCEPTO
 from {{ ref('s_factura_concepto') }}
), c as (select CODIGO_CONCEPTO from {{ ref('g_s_concepto_clasificacion') }})
select u.CODIGO_CONCEPTO from u left join c using(CODIGO_CONCEPTO)
where u.CODIGO_CONCEPTO is not null and c.CODIGO_CONCEPTO is null
