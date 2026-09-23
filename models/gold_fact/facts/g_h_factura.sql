{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','fact']) }}
with conceptos as (
 select HK_FACTURA,count(*) NUM_CONCEPTOS_TOTAL,
        count_if(TABLA_ORIGEN='L4_FACT_AIGUA') NUM_CONCEPTOS_AGUA,
        count_if(TABLA_ORIGEN='L4_FACT_CONCEPTE') NUM_CONCEPTOS_EXPLICITOS
 from {{ ref('s_factura_concepto') }} group by HK_FACTURA
), fraude as (
 select l.HK_SUBMIN_SERVEI,s.DATA_CREA_C_FRA,
        row_number() over(partition by l.HK_SUBMIN_SERVEI order by s.FECHA_CARGA desc,s.FECHA_EXTRACCION desc,s.ID_CARGA desc) RN
 from {{ ref('edw_l_submin_conveni_frau') }} l join {{ ref('edw_s_conveni_frau') }} s on s.HK_CONVENI_FRAU=l.HK_CONVENI_FRAU
)
select f.HK_FACTURA,coalesce(f.HK_SUBMIN_SERVEI,sha2_hex('SUMINISTRO|DESCONOCIDO',256)) HK_SUBMIN_SERVEI,
       coalesce(f.HK_TIPO_SUMINISTRO,sha2_hex('TIPO_SUMINISTRO|DESCONOCIDO',256)) HK_TIPO_SUMINISTRO,
       f.HK_TIPO_USO_AGUA,f.HK_TIPO_VIVIENDA,
       f.NUM_PARTICIO,f.ID_EMPRESA,f.ANY_FACTURA,f.NUM_FACTURA,f.POLISSA_SUBM,
       f.DATA_INI_FACT,f.DATA_FIN_FACT,f.DATA_EMISS_FACT,f.DATA_CARREC_RECAP,f.ANY_CALENDARI,f.MES_CALENDARI,f.FREQ_FACT,f.DIES_FACTURATS,
       f.TIP_SUBM_SERV as TIP_SUBM_SERV_FACTURA,f.US_AIGUA_SUBM_FACT,f.TIP_HABIT_SUBM_FA,f.NOMB_HABIT_FACT,f.SIT_SUBM_SERV_FACT,f.TIP_DOMESTIC,
       f.CONSUM_TOTAL_M3,f.IMP_TOTAL_FACT,f.IMP_AIGUA_IVA,
       coalesce(c.NUM_CONCEPTOS_TOTAL,0) NUM_CONCEPTOS_TOTAL,coalesce(c.NUM_CONCEPTOS_AGUA,0) NUM_CONCEPTOS_AGUA,
       coalesce(c.NUM_CONCEPTOS_EXPLICITOS,0) NUM_CONCEPTOS_EXPLICITOS,
       iff(upper(trim(f.ID_RECUPERACIO))='S',true,false) TIENE_RECUPERACION,
       iff(upper(trim(f.ID_REGULARITZACIO))='S',true,false) TIENE_REGULARIZACION,
       iff(exists(select 1 from {{ ref('g_b_suministro_actividad') }} a where a.HK_SUBMIN_SERVEI=f.HK_SUBMIN_SERVEI and a.ES_ACTIVIDAD_INDUSTRIAL_PRINCIPAL),true,false) TIENE_ACTIVIDAD_INDUSTRIAL,
       iff(exists(select 1 from {{ ref('g_b_suministro_colectivo') }} s where s.HK_SUBMIN_SERVEI=f.HK_SUBMIN_SERVEI and s.DATA_INI_IND<=f.DATA_FIN_FACT and (s.DATA_FIN_IND is null or f.DATA_FIN_FACT<=s.DATA_FIN_IND)),true,false) ES_VULNERABLE,
       iff(exists(select 1 from fraude x where x.HK_SUBMIN_SERVEI=f.HK_SUBMIN_SERVEI and x.RN=1 and x.DATA_CREA_C_FRA<=f.DATA_FIN_FACT),true,false) ES_FRAUDULENTA,
       f.ID_CARGA,f.FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,f.SISTEMA_ORIGEN,'S_FACTURA' TABLA_ORIGEN
from {{ ref('s_factura') }} f left join conceptos c on c.HK_FACTURA=f.HK_FACTURA
