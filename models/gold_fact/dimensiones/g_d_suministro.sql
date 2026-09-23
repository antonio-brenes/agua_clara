{{ config(
    materialized='table',
    schema='gold_fact',
    tags=['gold_fact', 'dimension']
) }}

with satellite as (
    select
        HK_SUBMIN_SERVEI,
        POLISSA_SUBM,
        TIP_SUBM_SERV,
        SIT_SUBM_SERV,
        US_AIGUA_SUBM,
        TIP_HABIT_SUBM,
        NOMB_HABIT_SUBM,
        DNI_NIF_CLIENT,
        NOM_TITULAR_COMPTE,
        NOM_COMERCIAL,
        ID_QUOTA_SOCIAL,
        ID_TARIFA_SOCIAL,
        IND_SERVEI_SOCIAL,
        IND_POB_ENERG,
        FECHA_EXTRACCION,
        FECHA_CARGA,
        SISTEMA_ORIGEN,
        TABLA_ORIGEN,
        row_number() over (
            partition by HK_SUBMIN_SERVEI
            order by FECHA_CARGA desc, FECHA_EXTRACCION desc, ID_CARGA desc
        ) as RN
    from {{ ref('edw_s_submin_servei') }}
)

select
    HK_SUBMIN_SERVEI,
    POLISSA_SUBM,
    TIP_SUBM_SERV,
    SIT_SUBM_SERV,
    US_AIGUA_SUBM,
    TIP_HABIT_SUBM,
    NOMB_HABIT_SUBM,
    DNI_NIF_CLIENT,
    NOM_TITULAR_COMPTE,
    NOM_COMERCIAL,
    ID_QUOTA_SOCIAL,
    ID_TARIFA_SOCIAL,
    IND_SERVEI_SOCIAL,
    IND_POB_ENERG,
    FECHA_EXTRACCION,
    CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) as FECHA_CARGA,
    SISTEMA_ORIGEN,
    'EDW_S_SUBMIN_SERVEI' as TABLA_ORIGEN
from satellite
where RN = 1
