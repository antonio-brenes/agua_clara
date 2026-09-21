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
4. Ejecutar `ddl/RAW_SICAB_DDL.sql` para crear las tablas RAW con todas las columnas VARCHAR y los metadatos de auditoría.
5. Ejecutar `ddl/COPY_INTO_RAW_SICAB.sql` para cargar los datos, informando `FECHA_EXTRACCION` y `SISTEMA_ORIGEN`.
6. Mantener las tablas RAW fuera de dbt: no crear modelos `raw_*.sql` materializados como tablas ni reemplazar estas tablas desde dbt.
7. Declarar las tablas cargadas externamente en `sources.yml` para que las capas posteriores las consuman mediante `source()`.
8. Validar técnicamente la ingesta: ficheros presentes en el stage, correspondencia fichero-tabla, recuentos de registros, número de columnas, errores de `COPY INTO` y metadatos de auditoría.
9. Ejecutar la validación de frescura de fuentes con `dbt source freshness`. El campo de referencia será `FECHA_EXTRACCION`, con aviso cuando la antigüedad supere 7 días y error cuando supere 15 días, según [docs/arquitectura_datos.md](docs/arquitectura_datos.md). Las tablas RAW vacías cuyo origen está pendiente quedan excluidas de esta validación.
10. Para cargas automatizadas mediante `scripts/load_raw_sicab.py`, usar autenticación key-pair mediante `SNOWFLAKE_PRIVATE_KEY_PATH` y `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE`; `scripts/generate_raw_sicab.py` solo genera SQL y no requiere credenciales.

Resultado esperado: raw_sicab cargado y gestionado por Snowflake, declarado como fuente externa de dbt y listo para l4_fact.

### Fase 3. Bronze: construcción de l4_fact
1. Mapear cada raw hacia su tabla bronze correspondiente: l4_<nombre_fichero>.
2. Aplicar conversiones tipificadas con TRY_TO_DATE, TRY_TO_NUMBER y TRY_TO_TIMESTAMP.
3. Añadir los campos de auditoría de la capa bronze: ID_CARGA, FECHA_EXTRACCION, FECHA_CARGA, SISTEMA_ORIGEN y TABLA_ORIGEN.
4. Verificar que la salida se alinea con el DDL de referencia en ddl/DDL_AGUA_CLARA.sql.
5. Generar modelos dbt de staging/bronze para cada entidad.
6. Derivar del DDL las validaciones de cada modelo: `not_null` para toda columna `NOT NULL`, `unique_combination_of_columns` para cada clave primaria y `relationships_compound` para toda clave foránea, incluidas las compuestas.
7. Documentar funcionalmente los modelos y columnas en castellano, usando la semántica del dominio de facturación y la nomenclatura catalana de las tablas y campos.
8. Añadir pruebas de calidad técnica.
9. Añadir reconciliaciones de recuentos RAW→L4 

La implementación cubrirá todas las tablas L4 definidas en el DDL.

Resultado esperado: bronze estructuralmente consistente y compatible con el DDL canonical del proyecto.

### Fase 4. Silver corporativa: modelo Data Vault 2.0 en silver_edw
1. Identificar entidades compartidas y reutilizables: l4_carrer, l4_dte_municipal, l4_epigraf_iae, l4_finca, l4_municipi_sgab, l4_ramal, l4_submin_iae, l4_submin_servei, l4_servei_eq_ci, l4_conveni_frau, l4_padro_tamgrem, l4_padro_trr y l4_hist_ss_pe.
2. Generar hubs, links y satellites con convención EDW_H_, EDW_L_ y EDW_S_, respectivamente. Excepcionalmente, dada su naturaleza, para l4_submin_iae se generará únicamente el link, pues los hubs asociados a dicho link serán EDW_H_SUBMIN_SERVEI y EDW_H_EPIGRAF_IAE.
3. Definir claves hash SHA2 y `HASHDIFF` explícitos sobre atributos de negocio, excluyendo claves y auditoría. `FECHA_CARGA` será el timestamp de llegada a la capa y `FECHA_EXTRACCION` conservará la cronología del origen.
4. Crear modelos adicionales para tipos de catálogo comunes (THL, TSS, US) de l4_codificacions, con sus hubs/satellites dedicados.
5. Generar los links necesarios a partir de claves foráneas presentes en l4_fact.
6. Añadir auditoría heredada del registro origen y documentación clara entre l4_fact y silver_edw.
7. Definir tests de Data Vault: integridad de hash, referential control, unicidad y evolución de satélites.
8. Añadir reconciliaciones de claves distintas L4→silver_edw.
9. Mantener en los hubs únicamente la HK, la clave natural y la auditoría; trasladar los atributos descriptivos a los satellites. Los catálogos derivados de `l4_codificacions` usarán nombres funcionales en castellano y no expondrán `TIP_CODI`.

Resultado esperado: silver_edw preparado para reutilización transversal y no solo para facturación.

### Fase 5. Silver de negocio: modelo estándar de facturación en silver_fact
1. Construir la entidad central S_FACTURA_LINEA como eje del dominio facturación. Esta tabla incorporará información de:
  - l4_fact_resum / l4_fact_aigua para consumos de agua
  - l4_fact_resum / l4_fact_concepte para resto de conceptos facturados
2. Vincular la línea de factura a datos de agua e información de conceptos mediante la composición adecuada entre l4_fact_resum, l4_fact_aigua y l4_fact_concepte.
3. Crear S_FACTURA_SITUACION_HIST para la historia de estados de la factura.
4. Crear las tablas S_CONCEPTO y S_SITUACION_FACTURA a partir de sendos tipos de código 'F25' y 'R01' de l4_codificacions. Estos catálogos derivados de `l4_codificacions` usarán nombres funcionales en castellano y no expondrán `TIP_CODI`.
5. Incorporar resto de entidades de negocio no cubiertas por silver_edw y que tengan utilidad directa para la facturación: l4_servei_facturar, l4_fact_recup y l4_fact_regul.
6. Generar la integridad referencial necesaria a partir de claves foráneas presentes en tablas correspondientes de l4_fact.
7. Añadir campos de auditoría: `FECHA_EXTRACCION` y `SISTEMA_ORIGEN` (heredados del registro origen, si hay más de uno, el valor mayor), `ID_CARGA` (heredado de registro o registros de l4_fact; si hay más de uno, el valor mayor), `FECHA_CARGA` (timestamp de llegada a la capa silver_fact) y `TABLA_ORIGEN` (tablas de l4_fact de las que procede el registro; si hay más una tabla1 + tabla2).
8. Documentar funcionalmente los modelos y columnas en castellano, usando la semántica del dominio de facturación y la nomenclatura catalana de las tablas y campos: directamente a partir de la descripción disponible para l4_fact, cuando sea posible, o aplicando la semántica y lógica de un negocio de facturación, cuando no lo sea.
9. Añadir validaciones para cada modelo: `not_null` para toda columna `NOT NULL` de l4_fact, `unique_combination_of_columns` para cada clave primaria y `relationships_compound` para toda clave foránea, incluidas las compuestas.
10. Generar tests funcionales: líneas sin factura, conceptos no catalogados, estados inválidos y sumarización de importes.
11. Añadir reconciliaciones de recuentos L4→silver_fact

Resultado esperado: silver_fact se convierte en la capa de negocio para análisis y consumo del dominio de facturación, esta capa es un dominio de negocio, no un Data Vault corporativo.

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
- [scripts/generate_raw_sicab.py](scripts/generate_raw_sicab.py) — generación automática de DDL, COPY INTO y fuentes RAW a partir de los CSV
- [scripts/generate_l4_fact.py](scripts/generate_l4_fact.py) — generación automática de modelos, tests y documentación de la capa L4
- [scripts/load_raw_sicab.py](scripts/load_raw_sicab.py) — carga de CSV a Snowflake mediante key-pair y validación técnica de RAW
- [macros/test_relationships_compound.sql](macros/test_relationships_compound.sql) — validación de claves foráneas simples y compuestas entre modelos L4
- [datos](datos) — CSV de entrada del dominio SICAB

Estos archivos son referencias obligatorias para ejecutar el plan. Antes de implementar o validar cada fase se deben revisar las definiciones, convenciones y reglas que correspondan en ellos. En particular, los umbrales de frescura de `raw_sicab` se toman de [docs/arquitectura_datos.md](docs/arquitectura_datos.md) y no se sustituyen por valores genéricos.

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
