# Plan de ejecución por capas: Agua Clara

TL;DR: el proyecto se ejecutará por etapas encadenadas y cada capa llevará asociados sus propios tests y su documentación, de forma que la validación y la descripción del dato formen parte de la propia construcción de la capa y no queden para el final.

## Principio operativo

Para cada capa del pipeline se seguirá siempre esta secuencia:
1. modelado de la capa
2. tests de calidad y consistencia
3. documentación dbt
4. validación frente a la capa anterior y a la siguiente dependiente

Esto aplica a:
- raw_sicab
- l4_fact
- silver_edw
- silver_fact
- gold_fact

## Fase 1. Preparación del proyecto y entorno
1. Validar la configuración del proyecto dbt y del perfil de Snowflake en dbt_project.yml.
2. Confirmar la convención de esquemas por entorno: desarrollo y producción, con aislamiento de esquemas por desarrollador en el entorno de desarrollo.
3. Revisar la macro de generación de esquema y la estrategia de nombres para asegurar compatibilidad con Snowflake.
4. Asegurar que la documentación base de la arquitectura esté alineada con la nomenclatura final.

## Fase 2. Capa raw_sicab
1. Definir la lista de CSV de entrada del dominio SICAB.
2. Crear una tabla raw por fichero: raw_<nombre_fichero>.
3. Mantener todas las columnas con tipo VARCHAR y conservar la cabecera original.
4. Añadir campos de auditoría: FECHA_EXTRACCION y SISTEMA_ORIGEN.
5. Diseñar la estrategia de carga con Snowflake Stage + COPY INTO.
6. Generar source.yml base para dbt.
7. Ejecutar tests de capa: frescura, no nulos, accepted values básicos y validación de formato.
8. Documentar la capa con tablas, columnas, reglas de origen y trazabilidad.

Resultado esperado: raw_sicab operativo, trazable y documentado.

## Fase 3. Capa l4_fact
1. Mapear cada raw hacia su tabla bronze correspondiente: l4_<nombre_fichero>.
2. Aplicar conversiones tipificadas con TRY_TO_DATE, TRY_TO_NUMBER y TRY_TO_TIMESTAMP.
3. Añadir campos de auditoría: ID_CARGA, FECHA_EXTRACCION, FECHA_CARGA, SISTEMA_ORIGEN y TABLA_ORIGEN.
4. Verificar la alineación con el DDL de referencia en ddl/DDL_AGUA_CLARA.sql.
5. Generar modelos dbt de staging/bronze para cada entidad.
6. Ejecutar tests de capa: unique, not null, integridad referencial y conciliación con raw.
7. Documentar la capa con definición de tablas, campos, claves, dependencias y reglas de negocio.

Resultado esperado: bronze consistente, validado y documentado.

## Fase 4. Capa silver_edw
1. Identificar entidades compartidas y reutilizables: carrer, dte_municipal, epigraf_iae, finca, municipi_sgab, ramal, submin_iae, submin_servei y servei_eq_ci.
2. Generar hubs, links y satellites con convención EDW_H_, EDW_L_ y EDW_S_.
3. Definir claves hash SHA2 y la lógica de persistencia de historial en satellites.
4. Crear modelos adicionales para tipos de catálogo comunes: THL, TSS y US.
5. Generar los links necesarios a partir de claves foráneas presentes en l4_fact.
6. Ejecutar tests de capa: integridad hash, referencias válidas, control de cambios en satellites y estabilidad de claves.
7. Documentar la capa con su arquitectura Data Vault y su trazabilidad desde l4_fact.

Resultado esperado: silver_edw reutilizable, validado y documentado.

## Fase 5. Capa silver_fact
1. Construir la entidad central S_FACTURA_LINEA.
2. Vincular la línea de factura a consumos de agua y conceptos facturados desde l4_fact_resum, l4_fact_aigua y l4_fact_concepte.
3. Crear S_FACTURA_SITUACION_HIST, S_CONCEPTO y S_SITUACION_FACTURA.
4. Incluir cualquier otra entidad de negocio no cubierta por silver_edw y con valor directo para la facturación.
5. Añadir auditoría y reglas de calidad de negocio.
6. Ejecutar tests de capa: líneas sin factura, conceptos no catalogados, estados inválidos y consistencia de importes.
7. Documentar la capa con definición de negocio, tablas, claves y relaciones funcionales.

Resultado esperado: silver_fact validada como modelo de negocio de facturación y documentada.

## Fase 6. Capa gold_fact
1. Definir el conjunto de hechos del modelo estrella, priorizando g_h_factura_linea y g_h_factura_situacion_hist.
2. Construir dimensiones con prefijo g_d_ tomando datos de silver_fact y silver_edw.
3. Incluir dimensión temporal si procede.
4. Mantener relaciones hecho-dimensión y asegurar integridad analítica.
5. Ejecutar tests de capa: integridad dimensional, reconciliación frente a silver_fact y silver_edw, y consistencia de claves.
6. Documentar la capa con la definición del esquema estrella y sus relaciones de BI.

Resultado esperado: gold_fact preparado para Power BI, validado y documentado.

## Fase 7. Revisión final y despliegue
1. Revisar que todas las capas cumplen la secuencia pedida: modelado + tests + documentación.
2. Ejecutar compilación global del proyecto y pruebas de integración entre capas.
3. Comprobar despliegue por entorno: desarrollo y producción, respetando la convención de esquemas.
4. Cerrar la iteración con un resumen ejecutivo del pipeline y de sus dependencias.

## Orden de ejecución recomendado
1. Preparación del entorno
2. raw_sicab + tests + documentación
3. l4_fact + tests + documentación
4. silver_edw + tests + documentación
5. silver_fact + tests + documentación
6. gold_fact + tests + documentación
7. revisión final y despliegue

## Regla de cierre por capa
Una capa se considera cerrada cuando:
- sus modelos compilan sin errores relevantes;
- sus tests pasan;
- su documentación dbt está actualizada;
- la capa es coherente con la precedente y reutilizable por la siguiente.

## Decisiones clave
- Se mantiene la nomenclatura de capas original del proyecto: raw_sicab, l4_fact, silver_fact, silver_edw y gold_fact.
- La capa silver_fact es estándar de negocio; la capa silver_edw es Data Vault 2.0.
- La capa gold_fact usa la convención final: g_d_ para dimensiones y g_h_ para hechos.
- Se documentan tests y documentación dentro de cada capa en el mismo bloque de ejecución.