{{ config(severity='error', store_failures=true, tags=['gold_fact','reconciliation','reconciliation_silver_gold']) }}
with controls as (
 select 'FACTURAS' CONTROL,(select count(*) from {{ ref('s_factura') }}) SILVER_COUNT,(select count(*) from {{ ref('g_h_factura') }}) GOLD_COUNT,
        (select coalesce(sum(IMP_TOTAL_FACT),0) from {{ ref('s_factura') }}) SILVER_VALUE,(select coalesce(sum(IMP_TOTAL_FACT),0) from {{ ref('g_h_factura') }}) GOLD_VALUE,
        0::number SILVER_VOLUME,0::number GOLD_VOLUME
 union all select 'CONCEPTOS',(select count(*) from {{ ref('s_factura_concepto') }}),(select count(*) from {{ ref('g_h_factura_concepto') }}),(select coalesce(sum(IMP_CONCEPTE),0) from {{ ref('s_factura_concepto') }}),(select coalesce(sum(IMP_CONCEPTE),0) from {{ ref('g_h_factura_concepto') }}),0,0
 union all select 'RECUPERACIONES',(select count(*) from {{ ref('s_factura_recup') }}),(select count(*) from {{ ref('g_h_recuperacion') }}),(select coalesce(sum(IMP_TOTAL_RECUPERACION),0) from {{ ref('s_factura_recup') }}),(select coalesce(sum(IMP_TOTAL_RECUPERACION),0) from {{ ref('g_h_recuperacion') }}),(select coalesce(sum(M3_TOTAL_RECUPERADOS),0) from {{ ref('s_factura_recup') }}),(select coalesce(sum(M3_TOTAL_RECUPERADOS),0) from {{ ref('g_h_recuperacion') }})
 union all select 'REGULARIZACIONES',(select count(*) from {{ ref('s_factura_regul') }}),(select count(*) from {{ ref('g_h_regularizacion') }}),(select coalesce(sum(IMP_TOTAL_REGULARIZACION),0) from {{ ref('s_factura_regul') }}),(select coalesce(sum(IMP_TOTAL_REGULARIZACION),0) from {{ ref('g_h_regularizacion') }}),(select coalesce(sum(M3_TOTAL_REGULARIZADOS),0) from {{ ref('s_factura_regul') }}),(select coalesce(sum(M3_TOTAL_REGULARIZADOS),0) from {{ ref('g_h_regularizacion') }})
 union all select 'SITUACIONES',(select count(*) from {{ ref('s_factura_situacion_hist') }}),(select count(*) from {{ ref('g_h_factura_situacion') }}),0,0,0,0
) select *,GOLD_COUNT-SILVER_COUNT COUNT_DIFFERENCE,GOLD_VALUE-SILVER_VALUE VALUE_DIFFERENCE,GOLD_VOLUME-SILVER_VOLUME VOLUME_DIFFERENCE
from controls where GOLD_COUNT<>SILVER_COUNT or abs(GOLD_VALUE-SILVER_VALUE)>.01 or abs(GOLD_VOLUME-SILVER_VOLUME)>.000001
