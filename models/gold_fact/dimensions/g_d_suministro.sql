{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with suministro as (
    select * from {{ ref('edw_s_submin_servei') }}
    qualify row_number() over (partition by HK_SUBMIN_SERVEI order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc)=1
),
suministro_finca as (
    select sr.HK_SUBMIN_SERVEI, fr.HK_FINCA
    from {{ ref('edw_l_submin_ramal') }} sr
    join {{ ref('edw_l_finca_ramal') }} fr on fr.HK_RAMAL = sr.HK_RAMAL
    qualify row_number() over (partition by sr.HK_SUBMIN_SERVEI order by fr.HK_FINCA)=1
),
tipo_suministro as (
    select * from {{ ref('edw_s_tipo_suministro') }}
    qualify row_number() over (partition by HK_TIPO_SUMINISTRO order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc)=1
),
tipo_uso_agua as (
    select * from {{ ref('edw_s_tipo_uso_agua') }}
    qualify row_number() over (partition by HK_TIPO_USO_AGUA order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc)=1
),
tipo_vivienda as (
    select * from {{ ref('edw_s_tipo_vivienda') }}
    qualify row_number() over (partition by HK_TIPO_VIVIENDA order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc)=1
)
select
    s.HK_SUBMIN_SERVEI, s.POLISSA_SUBM,
    coalesce(sha2_hex(upper(trim(s.DNI_NIF_CLIENT)),256),sha2_hex('DESCONOCIDO',256)) as HK_CLIENTE,
    coalesce(sf.HK_FINCA,sha2_hex('DESCONOCIDO',256)) as HK_GEOGRAFIA,
    s.COD_TIPO_SUMINISTRO as COD_TIPO_SUMINISTRO_ACTUAL,
    ts.DES_TIPO_SUMINISTRO as DES_TIPO_SUMINISTRO_ACTUAL,
    ts.DES_ABREV_TIPO_SUMINISTRO as DES_ABREV_TIPO_SUMINISTRO_ACTUAL,
    s.COD_TIPO_USO_AGUA as COD_TIPO_USO_AGUA_ACTUAL,
    tua.DES_TIPO_USO_AGUA as DES_TIPO_USO_AGUA_ACTUAL,
    tua.DES_ABREV_TIPO_USO_AGUA as DES_ABREV_TIPO_USO_AGUA_ACTUAL,
    s.COD_TIPO_VIVIENDA as COD_TIPO_VIVIENDA_ACTUAL,
    tv.DES_TIPO_VIVIENDA as DES_TIPO_VIVIENDA_ACTUAL,
    tv.DES_ABREV_TIPO_VIVIENDA as DES_ABREV_TIPO_VIVIENDA_ACTUAL,
    s.SIT_SUBM_SERV,s.NOMB_HABIT_SUBM,s.DNI_NIF_CLIENT,s.ID_QUOTA_SOCIAL,s.ID_TARIFA_SOCIAL,s.IND_SERVEI_SOCIAL,s.IND_POB_ENERG,
    s.ID_CARGA,s.FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,s.SISTEMA_ORIGEN,'EDW_S_SUBMIN_SERVEI' TABLA_ORIGEN
from suministro s
left join suministro_finca sf on sf.HK_SUBMIN_SERVEI=s.HK_SUBMIN_SERVEI
left join {{ ref('edw_l_submin_tipo_suministro') }} lts on lts.HK_SUBMIN_SERVEI=s.HK_SUBMIN_SERVEI and lts.HK_TIPO_SUMINISTRO=sha2_hex(upper(trim(s.COD_TIPO_SUMINISTRO)),256)
left join tipo_suministro ts on ts.HK_TIPO_SUMINISTRO=lts.HK_TIPO_SUMINISTRO
left join {{ ref('edw_l_submin_tipo_uso_agua') }} lua on lua.HK_SUBMIN_SERVEI=s.HK_SUBMIN_SERVEI and lua.HK_TIPO_USO_AGUA=sha2_hex(upper(trim(s.COD_TIPO_USO_AGUA)),256)
left join tipo_uso_agua tua on tua.HK_TIPO_USO_AGUA=lua.HK_TIPO_USO_AGUA
left join {{ ref('edw_l_submin_tipo_vivienda') }} ltv on ltv.HK_SUBMIN_SERVEI=s.HK_SUBMIN_SERVEI and ltv.HK_TIPO_VIVIENDA=sha2_hex(upper(trim(s.COD_TIPO_VIVIENDA)),256)
left join tipo_vivienda tv on tv.HK_TIPO_VIVIENDA=ltv.HK_TIPO_VIVIENDA
union all
select sha2_hex('DESCONOCIDO',256),'?',sha2_hex('DESCONOCIDO',256),sha2_hex('DESCONOCIDO',256),
       '?','Desconocido','Desconocido','?','Desconocido','Desconocido','?','Desconocido','Desconocido',
       null,-1,null,null,null,null,null,-1,null,convert_timezone('Europe/Madrid',current_timestamp()),'GOLD_FACT','G_D_SUMINISTRO'
