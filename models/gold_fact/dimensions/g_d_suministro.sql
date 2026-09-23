{{ config(materialized='table', schema='gold_fact', tags=['gold_fact','dimension']) }}
with sat as (
 select s.*, row_number() over(partition by HK_SUBMIN_SERVEI order by FECHA_CARGA desc,FECHA_EXTRACCION desc,ID_CARGA desc) RN
 from {{ ref('edw_s_submin_servei') }} s
), geo as (
 select sr.HK_SUBMIN_SERVEI, fr.HK_FINCA,
        row_number() over(partition by sr.HK_SUBMIN_SERVEI order by fr.HK_FINCA) RN
 from {{ ref('edw_l_submin_ramal') }} sr
 join {{ ref('edw_l_finca_ramal') }} fr on fr.HK_RAMAL=sr.HK_RAMAL
)
select s.HK_SUBMIN_SERVEI, s.POLISSA_SUBM,
       coalesce(sha2_hex('CLIENTE|'||upper(trim(s.DNI_NIF_CLIENT)),256),sha2_hex('CLIENTE|DESCONOCIDO',256)) as HK_CLIENTE,
       coalesce(g.HK_FINCA,sha2_hex('GEOGRAFIA|DESCONOCIDA',256)) as HK_GEOGRAFIA,
       s.TIP_SUBM_SERV, s.SIT_SUBM_SERV, s.US_AIGUA_SUBM, s.TIP_HABIT_SUBM, s.NOMB_HABIT_SUBM,
       s.DNI_NIF_CLIENT, s.ID_QUOTA_SOCIAL, s.ID_TARIFA_SOCIAL, s.IND_SERVEI_SOCIAL, s.IND_POB_ENERG,
       s.ID_CARGA,s.FECHA_EXTRACCION,convert_timezone('Europe/Madrid',current_timestamp()) FECHA_CARGA,
       s.SISTEMA_ORIGEN,'EDW_S_SUBMIN_SERVEI' TABLA_ORIGEN
from sat s left join geo g on g.HK_SUBMIN_SERVEI=s.HK_SUBMIN_SERVEI and g.RN=1 where s.RN=1
union all
select sha2_hex('SUMINISTRO|DESCONOCIDO',256),'DESCONOCIDO',sha2_hex('CLIENTE|DESCONOCIDO',256),sha2_hex('GEOGRAFIA|DESCONOCIDA',256),
       'D','D',null,null,null,null,null,null,null,null,0,null,convert_timezone('Europe/Madrid',current_timestamp()),'GOLD','EDW_S_SUBMIN_SERVEI'
