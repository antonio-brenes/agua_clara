{{ config(severity='error', store_failures=true, tags=['consistency','consistency_silver_fact']) }}
with lineas as (
 select c.NUM_PARTICIO,c.ID_EMPRESA,c.ANY_FACTURA,c.NUM_FACTURA,
   round(sum(iff(d.ES_CONSUMO,coalesce(c.CANTIDAD,0),0)),6) CONSUMO_TOTAL_M3,
   round(sum(iff(c.TABLA_ORIGEN='L4_FACT_AIGUA',coalesce(c.IMP_CONCEPTO,0),0)),2) IMPORTE_AGUA,
   round(sum(iff(d.ES_ADITIVO,coalesce(c.IMP_CONCEPTO,0),0)),2) IMPORTE_TOTAL_CONCEPTOS
 from {{ ref('s_factura_concepto') }} c join {{ ref('s_concepto') }} d on d.HK_CONCEPTO=c.HK_CONCEPTO
 group by c.NUM_PARTICIO,c.ID_EMPRESA,c.ANY_FACTURA,c.NUM_FACTURA
), controles as (
 select 'FACTURA_CONSUMO_TOTAL_DISTINTO' CONTROL,f.NUM_PARTICIO,f.ID_EMPRESA,f.ANY_FACTURA,f.NUM_FACTURA,
        round(coalesce(f.CONSUMO_TOTAL_M3,0),6) VALOR_FACTURA,round(coalesce(l.CONSUMO_TOTAL_M3,0),6) VALOR_CONCEPTOS
 from {{ ref('s_factura') }} f left join lineas l using(NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA)
 where abs(coalesce(f.CONSUMO_TOTAL_M3,0)-coalesce(l.CONSUMO_TOTAL_M3,0))>.000001
 union all
 select 'FACTURA_IMPORTE_AGUA_DISTINTO',f.NUM_PARTICIO,f.ID_EMPRESA,f.ANY_FACTURA,f.NUM_FACTURA,
        round(coalesce(f.IMP_AIGUA_IVA,0),2),round(coalesce(l.IMPORTE_AGUA,0),2)
 from {{ ref('s_factura') }} f left join lineas l using(NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA)
 where abs(coalesce(f.IMP_AIGUA_IVA,0)-coalesce(l.IMPORTE_AGUA,0))>.01
 union all
 select 'FACTURA_IMPORTE_TOTAL_DISTINTO',f.NUM_PARTICIO,f.ID_EMPRESA,f.ANY_FACTURA,f.NUM_FACTURA,
        round(coalesce(f.IMP_TOTAL_FACT,0),2),round(coalesce(l.IMPORTE_TOTAL_CONCEPTOS,0),2)
 from {{ ref('s_factura') }} f left join lineas l using(NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA)
 where abs(coalesce(f.IMP_TOTAL_FACT,0)-coalesce(l.IMPORTE_TOTAL_CONCEPTOS,0))>.01
) select *,VALOR_CONCEPTOS-VALOR_FACTURA DIFERENCIA from controles
