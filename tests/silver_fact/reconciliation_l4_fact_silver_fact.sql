{{ config(severity='error', store_failures=true, tags=['reconciliation','reconciliation_l4_silver_fact']) }}
with
l4_facturas as (
 select NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA,IMP_TOTAL_FACT from {{ ref('l4_fact_resum') }}
),
silver_facturas as (
 select NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA,IMP_TOTAL_FACT from {{ ref('s_factura') }}
),
l4_agua as (
 select NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA,
 round(coalesce(IMP_BLOC1,0)+coalesce(IMP_BLOC2,0)+coalesce(IMP_BLOC3,0)+coalesce(IMP_BLOC4,0)+coalesce(IMP_BLOC5,0)
 +coalesce(IMP_QTA_SERV,0)+coalesce(IMP_CT_XBASICA,0)+coalesce(IMP_TCG_SUBM,0)+coalesce(IMP_CLAVAG,0)+coalesce(IMP_SANEJA,0)
 +coalesce(IMP_ERSU,0)+coalesce(IMP_CIH_BLOC1,0)+coalesce(IMP_CIH_BLOC2,0)+coalesce(IMP_CIH_BLOC3,0)
 +coalesce(IMP_IVA_SANEJA,0)+coalesce(IMP_IVA,0),2) IMPORTE
 from {{ ref('l4_fact_aigua') }}
),
silver_agua as (
 select NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA,round(sum(coalesce(IMP_CONCEPTO,0)),2) IMPORTE
 from {{ ref('s_factura_concepto') }} where TABLA_ORIGEN='L4_FACT_AIGUA'
 group by NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA
),
l4_conceptos as (
 select NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA,NUM_LINEA,NUM_CONCEPTE,IMP_CONCEPTE from {{ ref('l4_fact_concepte') }}
),
silver_conceptos as (
 select NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA,NUM_LINEA,NUM_CONCEPTO,IMP_CONCEPTO
 from {{ ref('s_factura_concepto') }} where TABLA_ORIGEN='L4_FACT_CONCEPTE'
),
controles as (
 select 'FACTURA_RECUENTO' CONTROL,(select count(*) from silver_facturas) VALOR_SILVER,(select count(*) from l4_facturas) VALOR_L4
 union all
 select 'FACTURA_IMPORTE_GLOBAL',(select round(coalesce(sum(IMP_TOTAL_FACT),0),2) from silver_facturas),(select round(coalesce(sum(IMP_TOTAL_FACT),0),2) from l4_facturas)
 union all
 select 'AGUA_FACTURA_AUSENTE',count(*),0 from l4_agua l left join silver_agua s using(NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA) where s.NUM_FACTURA is null
 union all
 select 'AGUA_FACTURA_EXTRA',count(*),0 from silver_agua s left join l4_agua l using(NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA) where l.NUM_FACTURA is null
 union all
 select 'AGUA_IMPORTE_DISTINTO',count(*),0 from l4_agua l join silver_agua s using(NUM_PARTICIO,ID_EMPRESA,ANY_FACTURA,NUM_FACTURA) where abs(l.IMPORTE-s.IMPORTE)>.01
 union all
 select 'CONCEPTO_EXPLICITO_RECUENTO',(select count(*) from silver_conceptos),(select count(*) from l4_conceptos)
 union all
 select 'CONCEPTO_EXPLICITO_AUSENTE',count(*),0 from l4_conceptos l left join silver_conceptos s
  on s.NUM_PARTICIO=l.NUM_PARTICIO and s.ID_EMPRESA=l.ID_EMPRESA and s.ANY_FACTURA=l.ANY_FACTURA and s.NUM_FACTURA=l.NUM_FACTURA
 and s.NUM_LINEA=l.NUM_LINEA and s.NUM_CONCEPTO=l.NUM_CONCEPTE where s.NUM_FACTURA is null
 union all
 select 'CONCEPTO_EXPLICITO_EXTRA',count(*),0 from silver_conceptos s left join l4_conceptos l
  on l.NUM_PARTICIO=s.NUM_PARTICIO and l.ID_EMPRESA=s.ID_EMPRESA and l.ANY_FACTURA=s.ANY_FACTURA and l.NUM_FACTURA=s.NUM_FACTURA
 and l.NUM_LINEA=s.NUM_LINEA and l.NUM_CONCEPTE=s.NUM_CONCEPTO where l.NUM_FACTURA is null
 union all
 select 'CONCEPTO_EXPLICITO_IMPORTE_DISTINTO',count(*),0 from silver_conceptos s join l4_conceptos l
  on l.NUM_PARTICIO=s.NUM_PARTICIO and l.ID_EMPRESA=s.ID_EMPRESA and l.ANY_FACTURA=s.ANY_FACTURA and l.NUM_FACTURA=s.NUM_FACTURA
 and l.NUM_LINEA=s.NUM_LINEA and l.NUM_CONCEPTE=s.NUM_CONCEPTO where abs(coalesce(l.IMP_CONCEPTE,0)-coalesce(s.IMP_CONCEPTO,0))>.01
 union all
 select 'SITUACION_RECUENTO',(select count(*) from {{ ref('s_factura_situacion_hist') }}),(select count(*) from {{ ref('l4_situacio_fact') }})
 union all
 select 'RECUPERACION_RECUENTO',(select count(*) from {{ ref('s_factura_recup') }}),(select count(*) from {{ ref('l4_fact_recup') }})
 union all
 select 'REGULARIZACION_RECUENTO',(select count(*) from {{ ref('s_factura_regul') }}),(select count(*) from {{ ref('l4_fact_regul') }})
 union all
 select 'CATALOGO_CONCEPTO_RECUENTO',(select count(*) from {{ ref('s_concepto') }}),
   ((select count(*) from {{ ref('l4_codificacions') }} where TIP_CODI='F25' and upper(trim(CLAU_CODI)) not in ('CL1','CL2'))
    +(select count(*) from {{ ref('s_seed_conceptos_agua') }}))
) select *,VALOR_SILVER-VALOR_L4 DIFERENCIA from controles where coalesce(VALOR_SILVER,0)<>coalesce(VALOR_L4,0)
