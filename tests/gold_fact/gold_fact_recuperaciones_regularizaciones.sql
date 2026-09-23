{{ config(severity='error', store_failures=true, tags=['gold_fact','reconciliation','recuperaciones','regularizaciones']) }}
with rec as (
 select s.NUM_PARTICIO S_NUM_PARTICIO,s.ID_EMPRESA S_ID_EMPRESA,s.ANY_FACTURA S_ANY_FACTURA,s.NUM_FACTURA S_NUM_FACTURA,
        s.HK_FACTURA_RECUP S_CLAVE,s.HK_FACTURA S_HK_FACTURA,s.M3_TOTAL_RECUPERADOS S_VOL,s.IMP_TOTAL_RECUPERACION S_IMP,
        g.NUM_PARTICIO G_NUM_PARTICIO,g.ID_EMPRESA G_ID_EMPRESA,g.ANY_FACTURA G_ANY_FACTURA,g.NUM_FACTURA G_NUM_FACTURA,
        g.HK_FACTURA_RECUP G_CLAVE,g.HK_FACTURA G_HK_FACTURA,g.M3_TOTAL_RECUPERADOS G_VOL,g.IMP_TOTAL_RECUPERACION G_IMP
 from {{ ref('s_factura_recup') }} s full outer join {{ ref('g_h_recuperacion') }} g on g.HK_FACTURA_RECUP=s.HK_FACTURA_RECUP
), reg as (
 select s.NUM_PARTICIO S_NUM_PARTICIO,s.ID_EMPRESA S_ID_EMPRESA,s.ANY_FACTURA S_ANY_FACTURA,s.NUM_FACTURA S_NUM_FACTURA,s.DATA_FIN_PER_INCID S_FECHA,
        s.HK_FACTURA_REGUL S_CLAVE,s.HK_FACTURA S_HK_FACTURA,s.M3_TOTAL_REGULARIZADOS S_VOL,s.IMP_TOTAL_REGULARIZACION S_IMP,
        g.NUM_PARTICIO G_NUM_PARTICIO,g.ID_EMPRESA G_ID_EMPRESA,g.ANY_FACTURA G_ANY_FACTURA,g.NUM_FACTURA G_NUM_FACTURA,g.DATA_FIN_PER_INCID G_FECHA,
        g.HK_FACTURA_REGUL G_CLAVE,g.HK_FACTURA G_HK_FACTURA,g.M3_TOTAL_REGULARIZADOS G_VOL,g.IMP_TOTAL_REGULARIZACION G_IMP
 from {{ ref('s_factura_regul') }} s full outer join {{ ref('g_h_regularizacion') }} g on g.HK_FACTURA_REGUL=s.HK_FACTURA_REGUL
), failures as (
 select 'RECUPERACION' TIPO,coalesce(S_CLAVE,G_CLAVE) CLAVE,S_NUM_PARTICIO,S_ID_EMPRESA,S_ANY_FACTURA,S_NUM_FACTURA,
        G_NUM_PARTICIO,G_ID_EMPRESA,G_ANY_FACTURA,G_NUM_FACTURA,S_HK_FACTURA,G_HK_FACTURA,S_VOL,G_VOL,S_IMP,G_IMP
 from rec where S_CLAVE is null or G_CLAVE is null
    or coalesce(S_NUM_PARTICIO,-1)<>coalesce(G_NUM_PARTICIO,-1) or coalesce(S_ID_EMPRESA,'^^')<>coalesce(G_ID_EMPRESA,'^^')
    or coalesce(S_ANY_FACTURA,'^^')<>coalesce(G_ANY_FACTURA,'^^') or coalesce(S_NUM_FACTURA,-1)<>coalesce(G_NUM_FACTURA,-1)
    or coalesce(S_HK_FACTURA,'^^')<>coalesce(G_HK_FACTURA,'^^') or abs(coalesce(S_VOL,0)-coalesce(G_VOL,0))>.000001 or abs(coalesce(S_IMP,0)-coalesce(G_IMP,0))>.01
 union all
 select 'REGULARIZACION',coalesce(S_CLAVE,G_CLAVE),S_NUM_PARTICIO,S_ID_EMPRESA,S_ANY_FACTURA,S_NUM_FACTURA,
        G_NUM_PARTICIO,G_ID_EMPRESA,G_ANY_FACTURA,G_NUM_FACTURA,S_HK_FACTURA,G_HK_FACTURA,S_VOL,G_VOL,S_IMP,G_IMP
 from reg where S_CLAVE is null or G_CLAVE is null
    or coalesce(S_NUM_PARTICIO,-1)<>coalesce(G_NUM_PARTICIO,-1) or coalesce(S_ID_EMPRESA,'^^')<>coalesce(G_ID_EMPRESA,'^^')
    or coalesce(S_ANY_FACTURA,'^^')<>coalesce(G_ANY_FACTURA,'^^') or coalesce(S_NUM_FACTURA,-1)<>coalesce(G_NUM_FACTURA,-1)
    or coalesce(S_FECHA,'1900-01-01'::date)<>coalesce(G_FECHA,'1900-01-01'::date)
    or coalesce(S_HK_FACTURA,'^^')<>coalesce(G_HK_FACTURA,'^^') or abs(coalesce(S_VOL,0)-coalesce(G_VOL,0))>.000001 or abs(coalesce(S_IMP,0)-coalesce(G_IMP,0))>.01
) select * from failures
