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

El proceso no contiene credenciales. Requiere tener instalado Python y definir las variables de conexión en la sesión desde la que se ejecute.

#### Preparación

Desde la raíz del proyecto:

```powershell
python -m pip install -r requirements.txt
$env:SNOWFLAKE_ACCOUNT = "<cuenta>"
$env:SNOWFLAKE_USER = "<usuario>"
$env:SNOWFLAKE_PASSWORD = "<contraseña>"
$env:SNOWFLAKE_WAREHOUSE = "<warehouse>"
```

También se puede usar autenticación SSO, omitiendo `SNOWFLAKE_PASSWORD` y estableciendo:

```powershell
$env:SNOWFLAKE_AUTHENTICATOR = "externalbrowser"
```

`SNOWFLAKE_DATABASE` y `SNOWFLAKE_SCHEMA` son opcionales. Por defecto se utilizan `DES_AGUA_CLARA` y `RAW_SICAB`. El stage completo también puede cambiarse mediante `SNOWFLAKE_STAGE`.

#### Ejecución

Con los CSV disponibles en `datos` y las variables de conexión definidas, ejecutar:

```powershell
python .\scripts\load_raw_sicab.py
```

El script debe ejecutarse con un usuario que tenga permisos para crear o reemplazar el stage y las tablas del esquema RAW, subir ficheros al stage y ejecutar `COPY INTO`.

La carga asigna a cada registro los metadatos `FECHA_EXTRACCION` y `SISTEMA_ORIGEN`. `FECHA_EXTRACCION` se calcula convirtiendo explícitamente la hora actual a `Europe/Madrid`, respetando el cambio de horario de verano e invierno.

### Opción manual: ejecución paso a paso

Esta alternativa permite controlar y verificar cada operación individualmente. Las herramientas recomendadas son:

- **SnowSQL**: cliente de línea de comandos oficial de Snowflake, adecuado para ejecutar los ficheros SQL y comandos `PUT` desde Windows.
- **Snowflake CLI**: cliente oficial actual de Snowflake, también válido para ejecutar SQL y cargar ficheros locales al stage.
- **Snowsight**: interfaz web de Snowflake, adecuada para ejecutar y revisar SQL. Para subir ficheros locales mediante `PUT`, se recomienda utilizar SnowSQL o Snowflake CLI.

Para esta carga manual se recomienda utilizar SnowSQL o Snowflake CLI, ya que permiten ejecutar toda la secuencia desde el mismo entorno.

#### 1. Configurar la conexión

Configurar la conexión en SnowSQL o Snowflake CLI usando la cuenta, usuario, warehouse y método de autenticación de Snowflake. También puede utilizarse la conexión integrada de Snowsight para ejecutar SQL. No se deben escribir contraseñas en los ficheros del proyecto.

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

La opción manual debe respetar siempre este orden: crear el stage, subir los CSV, crear las tablas y ejecutar los `COPY INTO`.

## Implementación de la capa L4

La capa `l4_fact` transforma las tablas RAW declaradas en `models/agua_clara/raw_sicab/sources.yml` y se materializa mediante dbt como tablas tipadas. La ejecución genera los 21 modelos L4 definidos en el DDL, de los que 19 se alimentan desde RAW y 2 quedan vacíos a la espera de una decisión de diseño. Las conversiones son seguras mediante `TRY_TO_DATE`, `TRY_TO_NUMBER` y `TRY_TO_TIMESTAMP_NTZ`, además de los campos de auditoría definidos en el DDL de referencia.

Los modelos L4 no vuelven a cargar ni reemplazar las tablas RAW. `FECHA_EXTRACCION` se hereda de RAW y `FECHA_CARGA` se genera en `Europe/Madrid`.

Para regenerar los modelos, tests y documentación de la capa:

```powershell
python .\scripts\generate_l4_fact.py
dbt compile --select "models/agua_clara/l4_fact"
```

Las tablas `L4_FACT_REGUL` y `L4_FACT_RECUP` se generan con su estructura tipada, pero quedan vacías hasta que se defina su origen y estrategia de alimentación.
