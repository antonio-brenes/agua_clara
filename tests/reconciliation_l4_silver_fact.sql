{{ config(
    severity='error',
    store_failures=true,
    tags=['reconciliation', 'reconciliation_l4_silver_fact']
) }}

/*
    Reconciliacion L4 -> SILVER_FACT.

    Este test singular devuelve exclusivamente controles fallidos.
    Si todas las reconciliaciones son correctas, la consulta devuelve 0 filas.

    Criterios principales:
      - S_FACTURA conserva una fila por factura de L4_FACT_RESUM.
      - S_FACTURA_CONCEPTO es un modelo alto y delgado, por lo que no debe
        compararse su numero total de filas directamente con L4_FACT_AIGUA.
      - Para agua se valida cobertura por factura/particion e importe.
      - Para conceptos explicitos se valida cobertura por clave de linea e importe.
      - Los historicos y tablas auxiliares se validan contra su fuente L4 natural.
*/

with

l4_facturas as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        POLISSA_SUBM,
        IMP_TOTAL_FACT
    from {{ ref('l4_fact_resum') }}
),

silver_facturas as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        POLISSA_SUBM,
        IMP_TOTAL_FACT
    from {{ ref('s_factura') }}
),

l4_agua as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO
    from {{ ref('l4_fact_aigua') }}
),

/*
   Desnormalizacion controlada de los importes de L4_FACT_AIGUA.
   Debe utilizar exactamente los mismos tipos de concepto que S_FACTURA_CONCEPTO.
*/
l4_agua_importes as (
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'AIGUA_BLOC1' as TIPUS_CONCEPTE, coalesce(IMP_BLOC1, 0) as IMPORTE from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'AIGUA_BLOC2', coalesce(IMP_BLOC2, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'AIGUA_BLOC3', coalesce(IMP_BLOC3, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'AIGUA_BLOC4', coalesce(IMP_BLOC4, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'AIGUA_BLOC5', coalesce(IMP_BLOC5, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'QUOTA_SERVEI', coalesce(IMP_QTA_SERV, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'CT_XBASICA', coalesce(IMP_CT_XBASICA, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'TCG_SUBM', coalesce(IMP_TCG_SUBM, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'CLAVEGUERAM', coalesce(IMP_CLAVAG, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'SANEJAMENT', coalesce(IMP_SANEJA, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'ERSU', coalesce(IMP_ERSU, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'CIH_BLOC1', coalesce(IMP_CIH_BLOC1, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'CIH_BLOC2', coalesce(IMP_CIH_BLOC2, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'CIH_BLOC3', coalesce(IMP_CIH_BLOC3, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'IVA_SANEJAMENT', coalesce(IMP_IVA_SANEJA, 0) from {{ ref('l4_fact_aigua') }}
    union all
    select ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO, 'IVA', coalesce(IMP_IVA, 0) from {{ ref('l4_fact_aigua') }}
),

/*
   El modelo Silver omite componentes de agua cuyo importe, cantidad y base son cero.
   Por ello, para reconciliar importes se excluyen tambien los importes L4 iguales a cero.
*/
l4_agua_importes_aplicables as (
    select *
    from l4_agua_importes
    where abs(IMPORTE) > 0.005
),

silver_agua_importes as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        TIPUS_CONCEPTE,
        round(sum(coalesce(IMP_CONCEPTE, 0)), 2) as IMPORTE
    from {{ ref('s_factura_concepto') }}
    where TABLA_ORIGEN = 'L4_FACT_AIGUA'
    group by
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        TIPUS_CONCEPTE
),

l4_agua_totales as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        round(sum(IMPORTE), 2) as IMPORTE
    from l4_agua_importes
    group by ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO
),

silver_agua_totales as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        round(sum(coalesce(IMP_CONCEPTE, 0)), 2) as IMPORTE
    from {{ ref('s_factura_concepto') }}
    where TABLA_ORIGEN = 'L4_FACT_AIGUA'
    group by ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO
),

silver_agua_facturas as (
    select distinct
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO
    from {{ ref('s_factura_concepto') }}
    where TABLA_ORIGEN = 'L4_FACT_AIGUA'
),

l4_conceptos as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        NUM_LINEA,
        NUM_CONCEPTE,
        IMP_CONCEPTE
    from {{ ref('l4_fact_concepte') }}
),

silver_conceptos_explicitos as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        NUM_LINEA,
        NUM_CONCEPTE,
        IMP_CONCEPTE
    from {{ ref('s_factura_concepto') }}
    where TABLA_ORIGEN = 'L4_FACT_CONCEPTE'
),

l4_conceptos_totales as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        round(sum(coalesce(IMP_CONCEPTE, 0)), 2) as IMPORTE
    from l4_conceptos
    group by ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO
),

silver_conceptos_totales as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        round(sum(coalesce(IMP_CONCEPTE, 0)), 2) as IMPORTE
    from silver_conceptos_explicitos
    group by ID_EMPRESA, ANY_FACTURA, NUM_FACTURA, NUM_PARTICIO
),

l4_recuperaciones as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        round(
              coalesce(IMP_QTA_SERV_RC, 0)
            + coalesce(IMP_BLOC1_RC, 0)
            + coalesce(IMP_BLOC2_RC, 0)
            + coalesce(IMP_BLOC3_RC, 0)
            + coalesce(IMP_CT_XBASICA_RC, 0)
            + coalesce(IMP_TCG_SUBM_RC, 0)
            + coalesce(IMP_CLAVAG_RC, 0)
            + coalesce(IMP_SANEJA_RC, 0)
            + coalesce(IMP_ERSU_RC, 0)
            + coalesce(IMP_CIH_BLOC1_RC, 0)
            + coalesce(IMP_CIH_BLOC2_RC, 0)
            + coalesce(IMP_CIH_BLOC3_RC, 0)
            + coalesce(IMP_BONIF_QTA_RC, 0)
            + coalesce(IMP_CAI_T1_RC, 0)
            + coalesce(IMP_CAI_T2_RC, 0)
            + coalesce(IMP_CLA_T2_RC, 0)
            + coalesce(IMP_CAI_T3_RC, 0),
            2
        ) as IMP_TOTAL_RECUPERACION,
        round(
              coalesce(M3_BLOC1_RC, 0)
            + coalesce(M3_BLOC2_RC, 0)
            + coalesce(M3_BLOC3_RC, 0),
            6
        ) as M3_TOTAL_RECUPERADOS
    from {{ ref('l4_fact_recup') }}
),
silver_recuperaciones as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        round(coalesce(IMP_TOTAL_RECUPERACION, 0), 2) as IMP_TOTAL_RECUPERACION,
        round(coalesce(M3_TOTAL_RECUPERADOS, 0), 6) as M3_TOTAL_RECUPERADOS
    from {{ ref('s_factura_recup') }}
),
l4_regularizaciones as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        DATA_FIN_PER_INCID,
        round(
              coalesce(IMP_BLOC1_RG, 0)
            + coalesce(IMP_BLOC2_RG, 0)
            + coalesce(IMP_BLOC3_RG, 0)
            + coalesce(IMP_BLOC4_RG, 0)
            + coalesce(IMP_BLOC5_RG, 0)
            + coalesce(IMP_CT_XBASICA_RG, 0)
            + coalesce(IMP_TCG_SUBM_RG, 0)
            + coalesce(IMP_CTG_SUBM_RG, 0)
            + coalesce(IMP_CAN_BAELLS_RG, 0)
            + coalesce(IMP_CAN_TER_RG, 0)
            + coalesce(IMP_PRODUC_BRUT_RG, 0)
            + coalesce(IMP_CLAVAG_RG, 0)
            + coalesce(IMP_SANEJA_RG, 0)
            + coalesce(IMP_ERSU_RG, 0)
            + coalesce(IMP_CIH_BLOC1_RG, 0)
            + coalesce(IMP_CIH_BLOC2_RG, 0)
            + coalesce(IMP_CIH_BLOC3_RG, 0)
            + coalesce(IMP_CAI_T1_RG, 0)
            + coalesce(IMP_CAI_T2_RG, 0)
            + coalesce(IMP_CLA_T2_RG, 0)
            + coalesce(IMP_CAI_T3_RG, 0)
            + coalesce(IMP_CAI_T4_RG, 0),
            2
        ) as IMP_TOTAL_REGULARIZACION,
        round(
              coalesce(M3_BLOC1_RG, 0)
            + coalesce(M3_BLOC2_RG, 0)
            + coalesce(M3_BLOC3_RG, 0)
            + coalesce(M3_BLOC4_RG, 0)
            + coalesce(M3_BLOC5_RG, 0),
            6
        ) as M3_TOTAL_REGULARIZADOS
    from {{ ref('l4_fact_regul') }}
),
silver_regularizaciones as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        DATA_FIN_PER_INCID,
        round(coalesce(IMP_TOTAL_REGULARIZACION, 0), 2) as IMP_TOTAL_REGULARIZACION,
        round(coalesce(M3_TOTAL_REGULARIZADOS, 0), 6) as M3_TOTAL_REGULARIZADOS
    from {{ ref('s_factura_regul') }}
),
l4_situaciones as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        MOM_SIT_FACT
    from {{ ref('l4_situacio_fact') }}
),

silver_situaciones as (
    select
        ID_EMPRESA,
        ANY_FACTURA,
        NUM_FACTURA,
        NUM_PARTICIO,
        MOM_INI_SITUACION
    from {{ ref('s_factura_situacion_hist') }}
),

controles as (

    /* 1. Cabeceras de factura: recuento total. */
    select
        'FACTURA_RECUENTO' as CONTROL,
        'S_FACTURA' as MODELO_SILVER,
        'L4_FACT_RESUM' as MODELO_L4,
        (select count(*) from silver_facturas) as VALOR_SILVER,
        (select count(*) from l4_facturas) as VALOR_L4,
        'Numero total de facturas' as DETALLE

    union all

    /* 2. Cabeceras presentes en L4 y ausentes en Silver. */
    select
        'FACTURA_AUSENTE_EN_SILVER',
        'S_FACTURA',
        'L4_FACT_RESUM',
        count(*),
        0,
        'Facturas L4 sin correspondencia por empresa, anyo y numero'
    from l4_facturas as l4
    left join silver_facturas as sf
        on sf.ID_EMPRESA = l4.ID_EMPRESA
       and sf.ANY_FACTURA = l4.ANY_FACTURA
       and sf.NUM_FACTURA = l4.NUM_FACTURA
    where sf.NUM_FACTURA is null

    union all

    /* 3. Cabeceras extras en Silver que no existen en L4. */
    select
        'FACTURA_EXTRA_EN_SILVER',
        'S_FACTURA',
        'L4_FACT_RESUM',
        count(*),
        0,
        'Facturas Silver sin correspondencia en L4'
    from silver_facturas as sf
    left join l4_facturas as l4
        on l4.ID_EMPRESA = sf.ID_EMPRESA
       and l4.ANY_FACTURA = sf.ANY_FACTURA
       and l4.NUM_FACTURA = sf.NUM_FACTURA
    where l4.NUM_FACTURA is null

    union all

    /* 4. Importes de cabecera distintos. */
    select
        'FACTURA_IMPORTE_DISTINTO',
        'S_FACTURA',
        'L4_FACT_RESUM',
        count(*),
        0,
        'Facturas cuyo IMP_TOTAL_FACT no coincide'
    from l4_facturas as l4
    inner join silver_facturas as sf
        on sf.ID_EMPRESA = l4.ID_EMPRESA
       and sf.ANY_FACTURA = l4.ANY_FACTURA
       and sf.NUM_FACTURA = l4.NUM_FACTURA
    where abs(coalesce(sf.IMP_TOTAL_FACT, 0) - coalesce(l4.IMP_TOTAL_FACT, 0)) > 0.01

    union all

    /* 5. Cobertura del detalle de agua.
       Una fila L4_FACT_AIGUA puede producir varias filas normalizadas en Silver. */
    select
        'AGUA_FACTURA_PARTICION_AUSENTE',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_AIGUA',
        count(*),
        0,
        'Facturas/particiones de agua sin ningun componente normalizado'
    from l4_agua as la
    left join silver_agua_facturas as sa
        on sa.ID_EMPRESA = la.ID_EMPRESA
       and sa.ANY_FACTURA = la.ANY_FACTURA
       and sa.NUM_FACTURA = la.NUM_FACTURA
       and sa.NUM_PARTICIO = la.NUM_PARTICIO
    where sa.NUM_FACTURA is null

    union all

    /* 6. Componentes de agua sin cabecera de L4_FACT_AIGUA. */
    select
        'AGUA_FACTURA_PARTICION_EXTRA',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_AIGUA',
        count(*),
        0,
        'Facturas/particiones Silver de agua sin fila padre en L4_FACT_AIGUA'
    from silver_agua_facturas as sa
    left join l4_agua as la
        on la.ID_EMPRESA = sa.ID_EMPRESA
       and la.ANY_FACTURA = sa.ANY_FACTURA
       and la.NUM_FACTURA = sa.NUM_FACTURA
       and la.NUM_PARTICIO = sa.NUM_PARTICIO
    where la.NUM_FACTURA is null

    union all

    /* 7. Componentes monetarios de agua ausentes en Silver. */
    select
        'AGUA_CONCEPTO_AUSENTE',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_AIGUA',
        count(*),
        0,
        'Componentes con importe L4 distinto de cero sin concepto de agua equivalente en Silver'
    from l4_agua_importes_aplicables as la
    left join silver_agua_importes as sa
        on sa.ID_EMPRESA = la.ID_EMPRESA
       and sa.ANY_FACTURA = la.ANY_FACTURA
       and sa.NUM_FACTURA = la.NUM_FACTURA
       and sa.NUM_PARTICIO = la.NUM_PARTICIO
       and sa.TIPUS_CONCEPTE = la.TIPUS_CONCEPTE
    where sa.NUM_FACTURA is null

    union all

    /* 8. Componentes monetarios de agua extras en Silver. */
    select
        'AGUA_CONCEPTO_EXTRA',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_AIGUA',
        count(*),
        0,
        'Conceptos de agua Silver sin componente monetario aplicable en L4_FACT_AIGUA'
    from silver_agua_importes as sa
    left join l4_agua_importes_aplicables as la
        on la.ID_EMPRESA = sa.ID_EMPRESA
       and la.ANY_FACTURA = sa.ANY_FACTURA
       and la.NUM_FACTURA = sa.NUM_FACTURA
       and la.NUM_PARTICIO = sa.NUM_PARTICIO
       and la.TIPUS_CONCEPTE = sa.TIPUS_CONCEPTE
    where la.NUM_FACTURA is null
      and abs(coalesce(sa.IMPORTE, 0)) > 0.005

    union all

    /* 9. Importe distinto por factura, particion y componente de agua. */
    select
        'AGUA_CONCEPTO_IMPORTE_DISTINTO',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_AIGUA',
        count(*),
        0,
        'Componentes de agua cuyo importe transformado no coincide con el importe de origen'
    from l4_agua_importes_aplicables as la
    inner join silver_agua_importes as sa
        on sa.ID_EMPRESA = la.ID_EMPRESA
       and sa.ANY_FACTURA = la.ANY_FACTURA
       and sa.NUM_FACTURA = la.NUM_FACTURA
       and sa.NUM_PARTICIO = la.NUM_PARTICIO
       and sa.TIPUS_CONCEPTE = la.TIPUS_CONCEPTE
    where abs(round(la.IMPORTE, 2) - round(sa.IMPORTE, 2)) > 0.01

    union all

    /* 10. Cuadre total de agua por factura y particion. */
    select
        'AGUA_IMPORTE_TOTAL_DISTINTO',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_AIGUA',
        count(*),
        0,
        'Facturas/particiones cuyo total de conceptos de agua no coincide con la suma de importes L4_FACT_AIGUA'
    from l4_agua_totales as la
    full outer join silver_agua_totales as sa
        on sa.ID_EMPRESA = la.ID_EMPRESA
       and sa.ANY_FACTURA = la.ANY_FACTURA
       and sa.NUM_FACTURA = la.NUM_FACTURA
       and sa.NUM_PARTICIO = la.NUM_PARTICIO
    where la.NUM_FACTURA is null
       or sa.NUM_FACTURA is null
       or abs(coalesce(sa.IMPORTE, 0) - coalesce(la.IMPORTE, 0)) > 0.01

    union all

    /* 11. Cuadre monetario global de los conceptos de agua. */
    select
        'AGUA_IMPORTE_GLOBAL',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_AIGUA',
        round(coalesce((select sum(IMPORTE) from silver_agua_totales), 0), 2),
        round(coalesce((select sum(IMPORTE) from l4_agua_totales), 0), 2),
        'Suma global de todos los importes transformados desde L4_FACT_AIGUA'

    union all

    /* 12. Recuento de conceptos explicitos. */
    select
        'CONCEPTO_EXPLICITO_RECUENTO',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_CONCEPTE',
        (select count(*) from silver_conceptos_explicitos),
        (select count(*) from l4_conceptos),
        'Numero de lineas procedentes de L4_FACT_CONCEPTE'

    union all

    /* 13. Conceptos L4 ausentes en Silver por clave natural completa. */
    select
        'CONCEPTO_EXPLICITO_AUSENTE',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_CONCEPTE',
        count(*),
        0,
        'Lineas L4_FACT_CONCEPTE no normalizadas en Silver'
    from l4_conceptos as lc
    left join silver_conceptos_explicitos as sc
        on sc.ID_EMPRESA = lc.ID_EMPRESA
       and sc.ANY_FACTURA = lc.ANY_FACTURA
       and sc.NUM_FACTURA = lc.NUM_FACTURA
       and sc.NUM_PARTICIO = lc.NUM_PARTICIO
       and sc.NUM_LINEA = lc.NUM_LINEA
       and sc.NUM_CONCEPTE = lc.NUM_CONCEPTE
    where sc.NUM_FACTURA is null

    union all

    /* 14. Conceptos Silver extras. */
    select
        'CONCEPTO_EXPLICITO_EXTRA',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_CONCEPTE',
        count(*),
        0,
        'Lineas Silver marcadas como L4_FACT_CONCEPTE sin fila fuente'
    from silver_conceptos_explicitos as sc
    left join l4_conceptos as lc
        on lc.ID_EMPRESA = sc.ID_EMPRESA
       and lc.ANY_FACTURA = sc.ANY_FACTURA
       and lc.NUM_FACTURA = sc.NUM_FACTURA
       and lc.NUM_PARTICIO = sc.NUM_PARTICIO
       and lc.NUM_LINEA = sc.NUM_LINEA
       and lc.NUM_CONCEPTE = sc.NUM_CONCEPTE
    where lc.NUM_FACTURA is null

    union all

    /* 15. Importe distinto por factura, particion y concepto explicito. */
    select
        'CONCEPTO_EXPLICITO_IMPORTE_DISTINTO',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_CONCEPTE',
        count(*),
        0,
        'Lineas explicitas cuyo importe no coincide por factura, particion, linea y concepto'
    from l4_conceptos as lc
    inner join silver_conceptos_explicitos as sc
        on sc.ID_EMPRESA = lc.ID_EMPRESA
       and sc.ANY_FACTURA = lc.ANY_FACTURA
       and sc.NUM_FACTURA = lc.NUM_FACTURA
       and sc.NUM_PARTICIO = lc.NUM_PARTICIO
       and sc.NUM_LINEA = lc.NUM_LINEA
       and sc.NUM_CONCEPTE = lc.NUM_CONCEPTE
    where abs(round(coalesce(sc.IMP_CONCEPTE, 0), 2)
            - round(coalesce(lc.IMP_CONCEPTE, 0), 2)) > 0.01

    union all

    /* 16. Cuadre total de conceptos explicitos por factura y particion. */
    select
        'CONCEPTO_EXPLICITO_TOTAL_DISTINTO',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_CONCEPTE',
        count(*),
        0,
        'Facturas/particiones cuyo total de conceptos explicitos no coincide entre L4 y Silver'
    from l4_conceptos_totales as lc
    full outer join silver_conceptos_totales as sc
        on sc.ID_EMPRESA = lc.ID_EMPRESA
       and sc.ANY_FACTURA = lc.ANY_FACTURA
       and sc.NUM_FACTURA = lc.NUM_FACTURA
       and sc.NUM_PARTICIO = lc.NUM_PARTICIO
    where lc.NUM_FACTURA is null
       or sc.NUM_FACTURA is null
       or abs(coalesce(sc.IMPORTE, 0) - coalesce(lc.IMPORTE, 0)) > 0.01

    union all

    /* 17. Cuadre monetario global de conceptos explicitos. */
    select
        'CONCEPTO_EXPLICITO_IMPORTE',
        'S_FACTURA_CONCEPTO',
        'L4_FACT_CONCEPTE',
        round(coalesce((select sum(IMP_CONCEPTE) from silver_conceptos_explicitos), 0), 2),
        round(coalesce((select sum(IMP_CONCEPTE) from l4_conceptos), 0), 2),
        'Suma de IMP_CONCEPTE para conceptos explicitos'

    union all

    /* 18. Historico de situaciones: recuento. */
    select
        'SITUACION_RECUENTO',
        'S_FACTURA_SITUACION_HIST',
        'L4_SITUACIO_FACT',
        (select count(*) from silver_situaciones),
        (select count(*) from l4_situaciones),
        'Numero total de eventos de situacion'

    union all

    /* 19. Eventos de situacion ausentes. */
    select
        'SITUACION_AUSENTE_EN_SILVER',
        'S_FACTURA_SITUACION_HIST',
        'L4_SITUACIO_FACT',
        count(*),
        0,
        'Eventos L4 sin correspondencia por factura, particion y momento'
    from l4_situaciones as ls
    left join silver_situaciones as ss
        on ss.ID_EMPRESA = ls.ID_EMPRESA
       and ss.ANY_FACTURA = ls.ANY_FACTURA
       and ss.NUM_FACTURA = ls.NUM_FACTURA
       and ss.NUM_PARTICIO = ls.NUM_PARTICIO
       and ss.MOM_INI_SITUACION = ls.MOM_SIT_FACT
    where ss.NUM_FACTURA is null

    union all

    /* 20. Recuperaciones: recuento. */
    select
        'RECUP_RECUENTO',
        'S_FACTURA_RECUP',
        'L4_FACT_RECUP',
        (select count(*) from silver_recuperaciones),
        (select count(*) from l4_recuperaciones),
        'Numero total de recuperaciones'
    union all
    /* 21. Recuperaciones L4 ausentes en Silver. */
    select
        'RECUP_AUSENTE_EN_SILVER',
        'S_FACTURA_RECUP',
        'L4_FACT_RECUP',
        count(*),
        0,
        'Recuperaciones L4 sin correspondencia por empresa, anyo y factura'
    from l4_recuperaciones as l4
    left join silver_recuperaciones as sr
        on sr.ID_EMPRESA = l4.ID_EMPRESA
       and sr.ANY_FACTURA = l4.ANY_FACTURA
       and sr.NUM_FACTURA = l4.NUM_FACTURA
    where sr.NUM_FACTURA is null
    union all
    /* 22. Recuperaciones Silver extras. */
    select
        'RECUP_EXTRA_EN_SILVER',
        'S_FACTURA_RECUP',
        'L4_FACT_RECUP',
        count(*),
        0,
        'Recuperaciones Silver sin fila fuente en L4'
    from silver_recuperaciones as sr
    left join l4_recuperaciones as l4
        on l4.ID_EMPRESA = sr.ID_EMPRESA
       and l4.ANY_FACTURA = sr.ANY_FACTURA
       and l4.NUM_FACTURA = sr.NUM_FACTURA
    where l4.NUM_FACTURA is null
    union all
    /* 23. Recuperaciones con importe o volumen derivado distinto. */
    select
        'RECUP_VALOR_DISTINTO',
        'S_FACTURA_RECUP',
        'L4_FACT_RECUP',
        count(*),
        0,
        'Recuperaciones cuyo importe total o volumen total derivado no coincide'
    from l4_recuperaciones as l4
    inner join silver_recuperaciones as sr
        on sr.ID_EMPRESA = l4.ID_EMPRESA
       and sr.ANY_FACTURA = l4.ANY_FACTURA
       and sr.NUM_FACTURA = l4.NUM_FACTURA
    where abs(sr.IMP_TOTAL_RECUPERACION - l4.IMP_TOTAL_RECUPERACION) > 0.01
       or abs(sr.M3_TOTAL_RECUPERADOS - l4.M3_TOTAL_RECUPERADOS) > 0.000001
    union all
    /* 24. Regularizaciones: recuento. */
    select
        'REGUL_RECUENTO',
        'S_FACTURA_REGUL',
        'L4_FACT_REGUL',
        (select count(*) from silver_regularizaciones),
        (select count(*) from l4_regularizaciones),
        'Numero total de regularizaciones'
    union all
    /* 25. Regularizaciones L4 ausentes en Silver. */
    select
        'REGUL_AUSENTE_EN_SILVER',
        'S_FACTURA_REGUL',
        'L4_FACT_REGUL',
        count(*),
        0,
        'Regularizaciones L4 sin correspondencia por factura y fin de incidencia'
    from l4_regularizaciones as l4
    left join silver_regularizaciones as sr
        on sr.ID_EMPRESA = l4.ID_EMPRESA
       and sr.ANY_FACTURA = l4.ANY_FACTURA
       and sr.NUM_FACTURA = l4.NUM_FACTURA
       and sr.DATA_FIN_PER_INCID = l4.DATA_FIN_PER_INCID
    where sr.NUM_FACTURA is null
    union all
    /* 26. Regularizaciones Silver extras. */
    select
        'REGUL_EXTRA_EN_SILVER',
        'S_FACTURA_REGUL',
        'L4_FACT_REGUL',
        count(*),
        0,
        'Regularizaciones Silver sin fila fuente en L4'
    from silver_regularizaciones as sr
    left join l4_regularizaciones as l4
        on l4.ID_EMPRESA = sr.ID_EMPRESA
       and l4.ANY_FACTURA = sr.ANY_FACTURA
       and l4.NUM_FACTURA = sr.NUM_FACTURA
       and l4.DATA_FIN_PER_INCID = sr.DATA_FIN_PER_INCID
    where l4.NUM_FACTURA is null
    union all
    /* 27. Regularizaciones con importe o volumen derivado distinto. */
    select
        'REGUL_VALOR_DISTINTO',
        'S_FACTURA_REGUL',
        'L4_FACT_REGUL',
        count(*),
        0,
        'Regularizaciones cuyo importe total o volumen total derivado no coincide'
    from l4_regularizaciones as l4
    inner join silver_regularizaciones as sr
        on sr.ID_EMPRESA = l4.ID_EMPRESA
       and sr.ANY_FACTURA = l4.ANY_FACTURA
       and sr.NUM_FACTURA = l4.NUM_FACTURA
       and sr.DATA_FIN_PER_INCID = l4.DATA_FIN_PER_INCID
    where abs(sr.IMP_TOTAL_REGULARIZACION - l4.IMP_TOTAL_REGULARIZACION) > 0.01
       or abs(sr.M3_TOTAL_REGULARIZADOS - l4.M3_TOTAL_REGULARIZADOS) > 0.000001
    union all
    /* 28. Servicios CI preparados para facturar. */
    select
        'SERVICIO_CI_RECUENTO',
        'S_SERVICIO_CI_FACTURAR',
        'L4_SERVEI_FACTURAR',
        (select count(*) from {{ ref('s_servicio_ci_facturar') }}),
        (select count(*) from {{ ref('l4_servei_facturar') }}),
        'Numero total de servicios CI a facturar'

    union all

    /* 29. Catalogo de conceptos F25. */
    select
        'CATALOGO_CONCEPTO_RECUENTO',
        'S_CONCEPTO',
        'L4_CODIFICACIONS',
        (select count(*) from {{ ref('s_concepto') }}),
        (select count(*) from {{ ref('l4_codificacions') }} where TIP_CODI = 'F25'),
        'Numero de conceptos de la familia F25'

    union all

    /* 30. Catalogo de situaciones R01. */
    select
        'CATALOGO_SITUACION_RECUENTO',
        'S_SITUACION_FACTURA',
        'L4_CODIFICACIONS',
        (select count(*) from {{ ref('s_situacion_factura') }}),
        (select count(*) from {{ ref('l4_codificacions') }} where TIP_CODI = 'R01'),
        'Numero de situaciones de la familia R01'

)

select
    CONTROL,
    MODELO_SILVER,
    MODELO_L4,
    VALOR_SILVER,
    VALOR_L4,
    VALOR_SILVER - VALOR_L4 as DIFERENCIA,
    DETALLE
from controles
where coalesce(VALOR_SILVER, 0) <> coalesce(VALOR_L4, 0)
