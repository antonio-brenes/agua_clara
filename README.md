# Agua Clara

## Carga inicial de RAW SICAB

La carga inicial de los datos SICAB en Snowflake puede realizarse de forma automática, mediante el script del proyecto, o manualmente, ejecutando cada paso por separado.

### Opción automática: script del proyecto

El script `scripts/load_raw_sicab.py` realiza en una sola ejecución estas operaciones:

1. Crea o reemplaza el stage `DES_AGUA_CLARA.RAW_SICAB.RAW_STAGE`.
2. Sube los ficheros `*.csv` de la carpeta `datos` al stage, sin compresión y reemplazando versiones anteriores.
3. Ejecuta `ddl/RAW_SICAB_DDL.sql` para crear o reemplazar las tablas RAW.
4. Ejecuta `ddl/COPY_INTO_RAW_SICAB.sql` para cargar las tablas desde los ficheros del stage.
5. Valida técnicamente la ingesta: ficheros presentes, correspondencia fichero-tabla, número de columnas, recuentos de registros y metadatos de auditoría.

El proceso no contiene credenciales. Requiere tener instalado Python y definir las variables de conexión en la sesión desde la que se ejecute. La autenticación recomendada es key-pair.

#### Preparación

Desde la raíz del proyecto:

```powershell
python -m pip install -r requirements.txt
$env:SNOWFLAKE_ACCOUNT = "<cuenta>"
$env:SNOWFLAKE_USER = "<usuario>"
$env:SNOWFLAKE_WAREHOUSE = "<warehouse>"
$env:SNOWFLAKE_ROLE = "<rol>"
$env:SNOWFLAKE_PRIVATE_KEY_PATH = "C:\Users\<usuario>\.snowflake\rsa_key.p8"
$env:SNOWFLAKE_PRIVATE_KEY_PASSPHRASE = "<passphrase>"
```

La passphrase debe definirse únicamente en la sesión o en un gestor seguro; no debe escribirse en el repositorio, en scripts ni en documentación. También se puede usar autenticación SSO, omitiendo las variables key-pair y estableciendo:

```powershell
$env:SNOWFLAKE_AUTHENTICATOR = "externalbrowser"
```

`SNOWFLAKE_DATABASE` y `SNOWFLAKE_SCHEMA` son opcionales. Por defecto se utilizan `DES_AGUA_CLARA` y `RAW_SICAB`. El stage utilizado por el script es `RAW_STAGE`.

#### Ejecución

Con los CSV disponibles en `datos` y las variables de conexión definidas, ejecutar:

```powershell
python .\scripts\load_raw_sicab.py
```

El script debe ejecutarse con un usuario que tenga permisos para crear o reemplazar el stage y las tablas del esquema RAW, subir ficheros al stage y ejecutar `COPY INTO`.

La carga asigna a cada registro los metadatos `FECHA_EXTRACCION` y `SISTEMA_ORIGEN`. `FECHA_EXTRACCION` se almacena como `TIMESTAMP_TZ` y se calcula convirtiendo explícitamente la hora actual a `Europe/Madrid`, respetando el cambio de horario de verano e invierno.

Después de completar la carga RAW, validar la frescura de las fuentes declaradas en dbt:

```powershell
dbt source freshness
```

La frescura se calcula con `FECHA_EXTRACCION`: se emite aviso cuando la antigüedad supera 7 días y error cuando supera 15 días. 

### Opción manual: ejecución paso a paso

Esta alternativa permite controlar y verificar cada operación individualmente. Las herramientas recomendadas son:

- **SnowSQL**: cliente de línea de comandos oficial de Snowflake, adecuado para ejecutar los ficheros SQL y comandos `PUT` desde Windows.
- **Snowflake CLI**: cliente oficial actual de Snowflake, también válido para ejecutar SQL y cargar ficheros locales al stage.
- **Snowsight**: interfaz web de Snowflake, adecuada para ejecutar y revisar SQL. Para subir ficheros locales mediante `PUT`, se recomienda utilizar SnowSQL o Snowflake CLI.

Para esta carga manual se recomienda utilizar SnowSQL o Snowflake CLI, ya que permiten ejecutar toda la secuencia desde el mismo entorno.

#### 1. Configurar la conexión

Configurar la conexión en SnowSQL o Snowflake CLI usando cuenta, usuario, warehouse, rol y autenticación key-pair. La clave privada debe configurarse mediante el mecanismo seguro de la herramienta cliente y su passphrase no debe escribirse en los ficheros del proyecto. También puede utilizarse la conexión integrada de Snowsight para ejecutar SQL.

#### 2. Crear o reemplazar el stage

Ejecutar en Snowflake:

```sql
USE DATABASE DES_AGUA_CLARA;
USE SCHEMA RAW_SICAB;

CREATE OR REPLACE STAGE DES_AGUA_CLARA.RAW_SICAB.RAW_STAGE
	FILE_FORMAT = (
		TYPE = CSV
		FIELD_DELIMITER = ';'
		SKIP_HEADER = 1
		NULL_IF = ('', 'NULL')
	);
```

#### 3. Subir los CSV al stage

Ejecutar un comando `PUT` por cada fichero CSV de la carpeta `datos`, usando `AUTO_COMPRESS = FALSE` y `OVERWRITE = TRUE`. Por ejemplo, desde SnowSQL en Windows:

```sql
PUT 'file://C:/ruta/al/proyecto/agua_clara/datos/carrer.csv'
	@DES_AGUA_CLARA.RAW_SICAB.RAW_STAGE
	AUTO_COMPRESS = FALSE
	OVERWRITE = TRUE;
```

Repetir el comando para todos los ficheros CSV existentes en `datos`. La ruta debe ser absoluta y utilizar el formato aceptado por la herramienta cliente.

#### 4. Crear o reemplazar las tablas RAW

Ejecutar el contenido completo de `ddl/RAW_SICAB_DDL.sql`. Este fichero crea las 19 tablas de la capa RAW en `DES_AGUA_CLARA.RAW_SICAB`.

#### 5. Cargar las tablas desde el stage

Ejecutar el contenido completo de `ddl/COPY_INTO_RAW_SICAB.sql`. Cada sentencia carga su fichero correspondiente y añade:

- `FECHA_EXTRACCION`, convertido explícitamente a `Europe/Madrid` y respetando el horario de verano/invierno;
- `SISTEMA_ORIGEN`, con el valor `SICAB`.

#### 6. Verificar la carga

Comprobar que los 19 ficheros se encuentran en el stage y que las tablas tienen registros:

```sql
LIST @DES_AGUA_CLARA.RAW_SICAB.RAW_STAGE;

SELECT COUNT(*) FROM DES_AGUA_CLARA.RAW_SICAB.RAW_CARRER;
SELECT COUNT(*) FROM DES_AGUA_CLARA.RAW_SICAB.RAW_FACT_RESUM;
```

También conviene comprobar que los metadatos se han informado correctamente:

```sql
SELECT
	MIN(FECHA_EXTRACCION) AS PRIMERA_EXTRACCION,
	MAX(FECHA_EXTRACCION) AS ULTIMA_EXTRACCION,
	COUNT_IF(SISTEMA_ORIGEN = 'SICAB') AS REGISTROS_SICAB
FROM DES_AGUA_CLARA.RAW_SICAB.RAW_CARRER;
```

La opción manual debe respetar siempre este orden: crear el stage, subir los CSV, crear las tablas, ejecutar los `COPY INTO` y validar la frescura con `dbt source freshness`.

## Implementación de la capa L4

La capa `l4_fact` transforma las tablas RAW declaradas en `models/raw_sicab/sources.yml` y se materializa mediante dbt como tablas tipadas. La ejecución genera los 21 modelos L4 definidos en el DDL, de los que 19 se alimentan desde RAW y 2 quedan vacíos a la espera de una decisión de diseño. Las conversiones son seguras mediante `TRY_TO_DATE`, `TRY_TO_NUMBER` y `TRY_TO_TIMESTAMP_NTZ`, además de los campos de auditoría definidos en el DDL de referencia.

Los modelos L4 no vuelven a cargar ni reemplazar las tablas RAW. `FECHA_EXTRACCION` se hereda de RAW y `FECHA_CARGA` se genera en `Europe/Madrid`.

Para regenerar los modelos, tests y documentación de la capa:

```powershell
python .\scripts\generate_l4_fact.py
dbt compile --select "path:models/l4_fact"
```

Para materializar L4 y ejecutar únicamente los tests aplicables a esta capa, usar selección indirecta cautelosa:

```powershell
dbt build --select "path:models/l4_fact tag:reconciliation_raw_l4" --indirect-selection cautious
```

La reconciliación `reconciliation_raw_l4` comprueba la correspondencia entre RAW y L4. La reconciliación `reconciliation_l4_silver_edw` se ejecuta después de materializar `silver_edw`, incluyendo sus modelos y dependencias:

```powershell
dbt build --select "+path:models/silver_edw" --indirect-selection cautious
```

## Fase 5: Silver de negocio

La capa `silver_fact` contiene el modelo estándar de facturación: `s_factura_linea`, `s_factura_situacion_hist`, `s_concepto` y `s_situacion_factura`. La línea de factura separa las líneas funcionales `AIGUA` y `CONCEPTE`, conserva la clave lógica de factura y hereda la auditoría de las fuentes L4 combinadas.

Para compilar esta fase:

```powershell
dbt compile --select "path:models/silver_fact" "path:tests/reconciliation_l4_silver_fact.sql" "path:tests/silver_fact_*.sql"
```

La reconciliación `reconciliation_l4_silver_fact` comprueba los recuentos frente a L4. Los tests funcionales detectan líneas sin factura, conceptos no catalogados, estados inválidos y discrepancias entre importes de cabecera y detalle.
