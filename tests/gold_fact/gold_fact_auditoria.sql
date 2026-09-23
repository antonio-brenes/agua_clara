{{ config(severity='error', store_failures=true, tags=['gold_fact','audit']) }}
with checks as (
 select 'G_H_FACTURA' MODELO,g.HK_FACTURA CLAVE from {{ ref('g_h_factura') }} g join {{ ref('s_factura') }} s using(HK_FACTURA)
 where coalesce(g.ID_CARGA,-1)<>coalesce(s.ID_CARGA,-1) or coalesce(g.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)<>coalesce(s.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)
    or coalesce(g.SISTEMA_ORIGEN,'^^')<>coalesce(s.SISTEMA_ORIGEN,'^^') or g.TABLA_ORIGEN<>'S_FACTURA' or g.FECHA_CARGA is null
 union all
 select 'G_H_FACTURA_CONCEPTO',g.HK_FACTURA_CONCEPTE from {{ ref('g_h_factura_concepto') }} g join {{ ref('s_factura_concepto') }} s using(HK_FACTURA_CONCEPTE)
 where coalesce(g.ID_CARGA,-1)<>coalesce(s.ID_CARGA,-1) or coalesce(g.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)<>coalesce(s.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)
    or coalesce(g.SISTEMA_ORIGEN,'^^')<>coalesce(s.SISTEMA_ORIGEN,'^^') or g.TABLA_ORIGEN<>'S_FACTURA_CONCEPTO' or g.FECHA_CARGA is null
 union all
 select 'G_H_FACTURA_SITUACION',g.HK_FACTURA_SITUACION from {{ ref('g_h_factura_situacion') }} g join {{ ref('s_factura_situacion_hist') }} s using(HK_FACTURA_SITUACION)
 where coalesce(g.ID_CARGA,-1)<>coalesce(s.ID_CARGA,-1) or coalesce(g.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)<>coalesce(s.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)
    or coalesce(g.SISTEMA_ORIGEN,'^^')<>coalesce(s.SISTEMA_ORIGEN,'^^') or g.TABLA_ORIGEN<>'S_FACTURA_SITUACION_HIST' or g.FECHA_CARGA is null
 union all
 select 'G_H_RECUPERACION',g.HK_FACTURA_RECUP from {{ ref('g_h_recuperacion') }} g join {{ ref('s_factura_recup') }} s using(HK_FACTURA_RECUP)
 where coalesce(g.ID_CARGA,-1)<>coalesce(s.ID_CARGA,-1) or coalesce(g.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)<>coalesce(s.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)
    or coalesce(g.SISTEMA_ORIGEN,'^^')<>coalesce(s.SISTEMA_ORIGEN,'^^') or g.TABLA_ORIGEN<>'S_FACTURA_RECUP' or g.FECHA_CARGA is null
 union all
 select 'G_H_REGULARIZACION',g.HK_FACTURA_REGUL from {{ ref('g_h_regularizacion') }} g join {{ ref('s_factura_regul') }} s using(HK_FACTURA_REGUL)
 where coalesce(g.ID_CARGA,-1)<>coalesce(s.ID_CARGA,-1) or coalesce(g.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)<>coalesce(s.FECHA_EXTRACCION,'1900-01-01'::timestamp_tz)
    or coalesce(g.SISTEMA_ORIGEN,'^^')<>coalesce(s.SISTEMA_ORIGEN,'^^') or g.TABLA_ORIGEN<>'S_FACTURA_REGUL' or g.FECHA_CARGA is null
) select * from checks
