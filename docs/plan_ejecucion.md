## Plan: Proyecto Agua Clara por fases

TL;DR: el proyecto se ejecutará en etapas encadenadas desde la ingesta raw hasta la capa gold, manteniendo la arquitectura final documentada en [docs/arquitectura_datos.md](docs/arquitectura_datos.md). La estrategia prioriza la trazabilidad y la validación por capas: raw_sicab → l4_fact → silver_edw + silver_fact → gold_fact. La nomenclatura final queda resuelta: g_d_ para dimensiones y g_h_ para hechos, evitando la ambigüedad entre fact de “hecho” y fact de “facturación”.

### Fase 1. Preparación del proyecto y entorno
1. Validar la configuración del proyecto dbt y del perfil de Snowflake en [dbt_project.yml](dbt_project.yml) y el perfil local de conexión.
2. Confirmar la convención de esquemas por entorno: desarrollo y producción, con aislamiento de esquemas por desarrollador en entorno de desarrollo.
3. Revisar la macro de generación de esquema y la estrategia de nombres para asegurar compatibilidad con Snowflake y con la ruta del proyecto.
4. Asegurar que la documentación base se alinee con la última versión de [docs/arquitectura_datos.md](docs/arquitectura_datos.md), especialmente la capa raw, bronze, silver y gold.

Dependencias: sin dependencias previas; se ejecuta antes de cualquier modelo.

### Fase 2. Carga y estructuración raw_sicab
1. Definir la lista de CSV de entrada del dominio SICAB que van a cargarse.
2. Crear o reemplazar el stage `RAW_STAGE` en Snowflake.
3. Subir los CSV de `datos` al stage mediante el script de carga inicial o mediante la alternativa manual documentada.
4. Ejecutar `ddl/RAW_SICAB_DDL.sql` para crear las tablas RAW con todas las columnas VARCHAR y los metadatos de auditoría. Además de las 19 tablas asociadas a CSV, se crearán vacías `RAW_FACT_REGUL` y `RAW_FACT_RECUP` con la estructura de sus tablas L4 correspondientes.
5. Ejecutar `ddl/COPY_INTO_RAW_SICAB.sql` para cargar los datos, informando `FECHA_EXTRACCION` y `SISTEMA_ORIGEN`.
6. Mantener las tablas RAW fuera de dbt: no crear modelos `raw_*.sql` materializados como tablas ni reemplazar estas tablas desde dbt.
7. Declarar las tablas cargadas externamente en `sources.yml` para que las capas posteriores las consuman mediante `source()`.
8. Validar técnicamente la ingesta: ficheros presentes en el stage, correspondencia fichero-tabla, recuentos de registros, número de columnas, errores de `COPY INTO` y metadatos de auditoría.

Resultado esperado: raw_sicab cargado y gestionado por Snowflake, declarado como fuente externa de dbt y listo para l4_fact.

### Fase 3. Bronze: construcción de l4_fact
1. Mapear cada raw hacia su tabla bronze correspondiente: l4_<nombre_fichero>.
2. Aplicar conversiones tipificadas con TRY_TO_DATE, TRY_TO_NUMBER y TRY_TO_TIMESTAMP.
3. Añadir los campos de auditoría de la capa bronze: ID_CARGA, FECHA_EXTRACCION, FECHA_CARGA, SISTEMA_ORIGEN y TABLA_ORIGEN.
4. Verificar que la salida se alinea con el DDL de referencia en ddl/DDL_AGUA_CLARA.sql.
5. Generar modelos dbt de staging/bronze para cada entidad.
6. Añadir pruebas de calidad técnica: unique, not null, integridad referencial básica y reconciliación con raw.

La implementación cubrirá todas las tablas L4 definidas en el DDL. Las 19 tablas con correspondencia directa se alimentarán desde sus fuentes RAW. `L4_FACT_REGUL` y `L4_FACT_RECUP` se generarán con su estructura tipada, pero quedarán vacías porque el inventario actual no contiene CSV ni tablas RAW de origen para ellas; su futura alimentación queda pendiente de una decisión de diseño.

Resultado esperado: bronze estructuralmente consistente y compatible con el DDL canonical del proyecto.

### Fase 4. Silver corporativa: modelo Data Vault 2.0 en silver_edw
1. Identificar entidades compartidas y reutilizables: carrer, dte_municipal, epigraf_iae, finca, municipi_sgab, ramal, submin_iae, submin_servei y servei_eq_ci.
2. Generar hubs, links y satellites con convención EDW_H_, EDW_L_ y EDW_S_.
3. Definir claves hash SHA2 y la lógica de persistencia de historial en satellites.
4. Crear modelos adicionales para tipos de catálogo comunes (THL, TSS, US) con sus hubs/satellites dedicados.
5. Generar los links necesarios a partir de claves foráneas presentes en l4_fact.
6. Añadir auditoría heredada del registro origen y documentación clara entre l4_fact y silver_edw.
7. Definir tests de Data Vault: integridad de hash, referential control, unicidad y evolución de satélites.

Resultado esperado: silver_edw preparado para reutilización transversal y no solo para facturación.

### Fase 5. Silver de negocio: modelo estándar de facturación en silver_fact
1. Construir la entidad central S_FACTURA_LINEA como eje del dominio facturación.
2. Vincular la línea de factura a datos de agua e información de conceptos mediante la composición adecuada entre l4_fact_resum, l4_fact_aigua y l4_fact_concepte.
3. Crear S_FACTURA_SITUACION_HIST para la historia de estados de la factura.
4. Crear S_CONCEPTO a partir de codificacions F25 y S_SITUACION_FACTURA a partir de codificacions R01.
5. Incorporar cualquier otra entidad de negocio no cubierta por silver_edw y que tenga utilidad directa para la facturación.
6. Añadir auditoría de origen y reglas de calidad de negocio.
7. Generar tests funcionales: líneas sin factura, conceptos no catalogados, estados inválidos y sumarización de importes.

Resultado esperado: silver_fact se convierte en la capa de negocio para análisis y consumo del dominio de facturación.

### Fase 6. Gold analítico: modelo estrella en gold_fact
1. Definir el conjunto de hechos del modelo estrella, con prioridad en g_h_factura_linea y g_h_factura_situacion_hist.
2. Construir las dimensiones necesarias con prefijo g_d_ sobre la base de silver_fact y silver_edw.
3. Incluir dimensión temporal cuando el análisis lo requiera.
4. Mantener la relación hecho-dimensión y asegurar integridad analítica con claves estables.
5. Añadir auditoría heredada de la capa fuente.
6. Crear tests de consistencia dimensional y reconciliación frente a silver_fact / silver_edw.
7. Preparar la capa para consumo directo en Power BI.

Resultado esperado: gold_fact listo para analítica y reporting empresarial, con nomenclatura unificada y semántica clara.

### Fase 7. Validación y documentación dentro de cada capa
1. Una vez creada la capa, aplicar tests de calidad específicos a esa misma capa.
2. Generar la documentación dbt de esa capa antes de cerrar la ejecución del modelo: descripción de tablas, campos, claves primarias, claves foráneas y reglas funcionales.
3. Validar la coherencia con la capa precedente antes de pasar a la siguiente.
4. Repetir la operación en cada capa: raw_sicab, l4_fact, silver_edw, silver_fact y gold_fact.
5. Dejar la documentación y la validación como parte inseparable de la propia ejecución de la capa.

Resultado esperado: cada capa queda validada y documentada en el mismo momento de su generación, sin dejar estas tareas para el final.

### Fase 8. Orden de ejecución recomendado
1. Configuración de entorno y base de proyecto.
2. raw_sicab + tests + documentación
3. l4_fact + tests + documentación
4. silver_edw + tests + documentación
5. silver_fact + tests + documentación
6. gold_fact + tests + documentación
7. revisión final de despliegue y entorno

Este orden evita depender de modelos no materializados y mantiene la trazabilidad, validación y documentación en cada etapa.

### Regla de ejecución por capa
Para cada capa del pipeline, la secuencia será siempre:
1. modelado del dato
2. tests de calidad y consistencia
3. documentación dbt
4. validación frente a la capa anterior y a la siguiente dependiente

Esto hace que cada capa sea autocontenida, verificable y reutilizable a la vez que se genera.

### Regla para generación automática
Cuando se genere una estructura automáticamente desde un CSV, la secuencia debe respetar también esta regla por capa:
1. crear la tabla raw y la carga inicial;
2. generar stage/bronze y los tests de la capa;
3. generar la documentación de esa capa;
4. pasar a la siguiente capa solo si la coherencia con la anterior es correcta;
5. repetir el mismo patrón en silver_edw, silver_fact y gold_fact.

### Archivos relevantes
- [docs/arquitectura_datos.md](docs/arquitectura_datos.md) — arquitectura y convenciones de capa y nomenclatura
- [dbt_project.yml](dbt_project.yml) — configuración del proyecto dbt y capas
- [macros/generate_schema_name.sql](macros/generate_schema_name.sql) — lógica de naming de esquema
- [ddl/DDL_AGUA_CLARA.sql](ddl/DDL_AGUA_CLARA.sql) — referencia técnica de bronze y modelo de datos

### Decisiones clave tomadas
- Se mantiene la nomenclatura de capas original del proyecto: raw_sicab, l4_fact, silver_fact, silver_edw y gold_fact.
- La capa silver_fact es modelo de negocio estándar; la capa silver_edw es Data Vault corporativo.
- La capa gold_fact usa la convención definitiva de nombres: g_d_ para dimensiones y g_h_ para hechos.
- El alcance del piloto sigue siendo funcional y no integral del universo SICAB; se trabaja en la facturación del dominio concreto definido.

### Verificación del plan
1. ejecutar dbt debug para confirmar entorno y conexión
2. validar compilación del proyecto con dbt compile
3. comprobar cada capa en orden por dependencias
4. asegurar tests de calidad y documentación por capa antes de declarar una fase completa

### Criterio de cierre por fase
Se considera una fase cerrada cuando:
- la capa compila correctamente en dbt;
- la lógica de transformación está documentada;
- existen pruebas mínimas de calidad;
- la salida puede ser usada por la siguiente fase sin ambigüedad.
