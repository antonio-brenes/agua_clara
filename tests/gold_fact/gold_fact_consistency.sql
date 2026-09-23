{{ config(severity='error', store_failures=true, tags=['gold_fact','consistency']) }}
with lineas as (
 select c.HK_FACTURA,
        sum(iff(c.ORIGEN_CONCEPTO='L4_FACT_AIGUA',c.IMP_CONCEPTE,0)) IMP_AGUA_IVA,
        sum(iff(c.TIPUS_CONCEPTE like 'AIGUA_BLOC%',coalesce(c.QUANTITAT,0),0)) CONSUM_TOTAL_M3,
        sum(iff(d.ES_ADITIVO,c.IMP_CONCEPTE,0)) IMP_TOTAL_FACT
 from {{ ref('g_h_factura_concepto') }} c join {{ ref('g_d_concepto') }} d using(CODIGO_CONCEPTO) group by c.HK_FACTURA
), r as (select HK_FACTURA,count(*) N from {{ ref('g_h_recuperacion') }} group by HK_FACTURA),
g as (select HK_FACTURA,count(*) N from {{ ref('g_h_regularizacion') }} group by HK_FACTURA),
checks as (
 select 'AGUA' CONTROL,f.HK_FACTURA from {{ ref('g_h_factura') }} f left join lineas l using(HK_FACTURA)
 where abs(coalesce(f.IMP_AIGUA_IVA,0)-coalesce(l.IMP_AGUA_IVA,0))>.01 or abs(coalesce(f.CONSUM_TOTAL_M3,0)-coalesce(l.CONSUM_TOTAL_M3,0))>.000001
 union all select 'TOTAL',f.HK_FACTURA from {{ ref('g_h_factura') }} f left join lineas l using(HK_FACTURA) where abs(coalesce(f.IMP_TOTAL_FACT,0)-coalesce(l.IMP_TOTAL_FACT,0))>.01
 union all select 'CI_CON_AGUA',c.HK_FACTURA from {{ ref('g_h_factura_concepto') }} c join {{ ref('g_h_factura') }} f using(HK_FACTURA) where f.TIP_SUBM_SERV_FACTURA='C' and c.ORIGEN_CONCEPTO='L4_FACT_AIGUA' group by c.HK_FACTURA
 union all select 'INDICADOR_RECUPERACION',f.HK_FACTURA from {{ ref('g_h_factura') }} f left join r using(HK_FACTURA) where f.TIENE_RECUPERACION<>iff(coalesce(r.N,0)>0,true,false)
 union all select 'INDICADOR_REGULARIZACION',f.HK_FACTURA from {{ ref('g_h_factura') }} f left join g using(HK_FACTURA) where f.TIENE_REGULARIZACION<>iff(coalesce(g.N,0)>0,true,false)
) select * from checks
