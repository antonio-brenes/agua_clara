{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with utilizados as (
 select distinct
   case when TABLA_ORIGEN='L4_FACT_AIGUA' and TIPUS_CONCEPTE is not null then 'AIGUA:'||TIPUS_CONCEPTE
        when TABLA_ORIGEN='L4_FACT_CONCEPTE' and NUM_CONCEPTE is not null then 'CONCEPTE:'||NUM_CONCEPTE
        else 'DESCONOCIDO' end CODIGO_CONCEPTO,
   case when TABLA_ORIGEN='L4_FACT_AIGUA' then TIPUS_CONCEPTE else NUM_CONCEPTE end CODIGO_ORIGEN,
   DESC_CONCEPTE DESCRIPCION, TABLA_ORIGEN as ORIGEN_CONCEPTO, ID_CARGA,FECHA_EXTRACCION,SISTEMA_ORIGEN
 from {{ ref('s_factura_concepto') }}
 qualify row_number() over(partition by CODIGO_CONCEPTO order by FECHA_CARGA desc,FECHA_EXTRACCION desc,ID_CARGA desc)=1
), cat as (
 select 'CONCEPTE:'||NUM_CONCEPTE CODIGO_CONCEPTO,DESC_BREU_CONCEPTE DESCRIPCION_BREVE from {{ ref('s_concepto') }}
), sem as (select * from {{ ref('g_s_concepto_clasificacion') }})
select u.CODIGO_CONCEPTO,u.CODIGO_ORIGEN,u.DESCRIPCION,coalesce(cat.DESCRIPCION_BREVE,u.DESCRIPCION) DESCRIPCION_BREVE,
       coalesce(s.GRUPO_FUNCIONAL,'OTROS') GRUPO_FUNCIONAL,coalesce(s.ES_CONSUMO,false) ES_CONSUMO,
       coalesce(s.ES_SERVICIO,false) ES_SERVICIO,coalesce(s.ES_TRIBUTO,false) ES_TRIBUTO,
       coalesce(s.ES_BONIFICACION,false) ES_BONIFICACION,coalesce(s.ES_IVA,false) ES_IVA,coalesce(s.ES_ADITIVO,true) ES_ADITIVO,
       u.ORIGEN_CONCEPTO,u.ID_CARGA,u.FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,
       u.SISTEMA_ORIGEN,'S_FACTURA_CONCEPTO' TABLA_ORIGEN
from utilizados u left join cat on cat.CODIGO_CONCEPTO=u.CODIGO_CONCEPTO left join sem s on s.CODIGO_CONCEPTO=u.CODIGO_CONCEPTO
union all select 'DESCONOCIDO','DESCONOCIDO','Desconocido','Desconocido','OTROS',false,false,false,false,false,true,
'GOLD',0,null,convert_timezone('Europe/Madrid',current_timestamp()),'GOLD','S_FACTURA_CONCEPTO'
