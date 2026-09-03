"""Carga inicial de los CSV SICAB en Snowflake."""

from __future__ import annotations

import os
import sys
import csv
from pathlib import Path
from typing import Any
from urllib.parse import unquote


BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "datos"
DDL_DIR = BASE_DIR / "ddl"
DATABASE = os.getenv("SNOWFLAKE_DATABASE", "DES_AGUA_CLARA")
SCHEMA = os.getenv("SNOWFLAKE_SCHEMA", "RAW_SICAB")
STAGE = "RAW_STAGE"


def require_environment() -> dict[str, Any]:
    """Build connection parameters without putting credentials in the repository."""
    required = {"account": "SNOWFLAKE_ACCOUNT", "user": "SNOWFLAKE_USER"}
    missing = [variable for variable in required.values() if not os.getenv(variable)]
    if missing:
        names = ", ".join(missing)
        raise RuntimeError(f"Faltan variables de conexión obligatorias: {names}")

    connection: dict[str, Any] = {
        "account": os.environ["SNOWFLAKE_ACCOUNT"],
        "user": os.environ["SNOWFLAKE_USER"],
        "database": DATABASE,
        "schema": SCHEMA,
        "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
        "role": os.getenv("SNOWFLAKE_ROLE"),
    }
    authenticator = os.getenv("SNOWFLAKE_AUTHENTICATOR")
    if authenticator:
        connection["authenticator"] = authenticator
    elif os.getenv("SNOWFLAKE_PASSWORD"):
        connection["password"] = os.environ["SNOWFLAKE_PASSWORD"]
    else:
        connection["authenticator"] = "externalbrowser"

    return {key: value for key, value in connection.items() if value is not None}


def execute_sql_file(connection: Any, path: Path) -> None:
    """Execute all statements in a Snowflake SQL file."""
    print(f"Ejecutando {path.relative_to(BASE_DIR)}")
    sql = path.read_text(encoding="utf-8-sig")
    connection.execute_string(sql)


def validate_raw_load(cursor: Any, csv_files: list[Path]) -> None:
    """Validate the technical result of the external RAW ingestion."""
    cursor.execute(f"LIST @{STAGE}")
    staged_files = {
        unquote(str(row[0])).rsplit("/", 1)[-1].lower()
        for row in cursor.fetchall()
    }
    expected_files = {csv_file.name.lower() for csv_file in csv_files}
    missing_files = sorted(expected_files - staged_files)
    if missing_files:
        raise RuntimeError(f"Ficheros no encontrados en el stage: {', '.join(missing_files)}")

    for csv_file in csv_files:
        with csv_file.open("r", encoding="latin-1", newline="") as source_file:
            sample = source_file.read(4096)
            source_file.seek(0)
            quotechar = '"' if '"' in sample else None
            header = next(csv.reader(source_file, delimiter=";", quotechar=quotechar), [])

        table_name = f"RAW_{csv_file.stem}".upper()
        cursor.execute(
            f"SELECT COUNT(*) FROM {DATABASE}.INFORMATION_SCHEMA.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
            (SCHEMA, table_name),
        )
        column_count = cursor.fetchone()[0]
        expected_column_count = len(header) + 2
        if column_count != expected_column_count:
            raise RuntimeError(
                f"{table_name}: se esperaban {expected_column_count} columnas y "
                f"se encontraron {column_count}"
            )

        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        row_count = cursor.fetchone()[0]
        if row_count == 0:
            raise RuntimeError(f"{table_name}: la tabla no contiene registros")

        cursor.execute(
            f"SELECT COUNT(*), COUNT(FECHA_EXTRACCION), COUNT(SISTEMA_ORIGEN), "
            f"COUNT_IF(SISTEMA_ORIGEN = 'SICAB') FROM {table_name}"
        )
        total, extraction_count, source_count, sicab_count = cursor.fetchone()
        if extraction_count != total or source_count != total or sicab_count != total:
            raise RuntimeError(f"{table_name}: metadatos de auditoría incompletos o incorrectos")

        print(f"Validada {table_name}: {row_count} registros, {column_count} columnas")


def main() -> int:
    try:
        import snowflake.connector
    except ImportError as error:
        raise RuntimeError(
            "Falta snowflake-connector-python. Instálalo con: "
            "python -m pip install -r requirements.txt"
        ) from error

    csv_files = sorted(DATA_DIR.glob("*.csv"))
    if not csv_files:
        raise RuntimeError(f"No se han encontrado ficheros CSV en {DATA_DIR}")

    ddl_path = DDL_DIR / "RAW_SICAB_DDL.sql"
    copy_path = DDL_DIR / "COPY_INTO_RAW_SICAB.sql"
    for path in (ddl_path, copy_path):
        if not path.exists():
            raise RuntimeError(f"No existe el fichero requerido: {path}")

    connection = None
    try:
        print(f"Conectando a Snowflake; destino: {DATABASE}.{SCHEMA}")
        connection = snowflake.connector.connect(**require_environment())
        cursor = connection.cursor()
        cursor.execute(f"USE DATABASE {DATABASE}")
        cursor.execute(f"USE SCHEMA {SCHEMA}")
        cursor.execute(
            f"CREATE OR REPLACE STAGE {STAGE} "
            "FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ';' "
            "SKIP_HEADER = 1 NULL_IF = ('', 'NULL'))"
        )
        print(f"Stage creado o reemplazado: {STAGE}")

        for csv_file in csv_files:
            # Snowflake Connector no decodifica los espacios codificados como %20.
            file_uri = f"file://{csv_file.resolve().as_posix()}"
            print(f"Subiendo {csv_file.name}")
            cursor.execute(
                f"PUT '{file_uri}' @{STAGE} AUTO_COMPRESS = FALSE OVERWRITE = TRUE"
            )

        execute_sql_file(connection, ddl_path)
        execute_sql_file(connection, copy_path)
        validate_raw_load(cursor, csv_files)
        connection.commit()
        print(f"Carga completada: {len(csv_files)} ficheros CSV")
        return 0
    except Exception:
        if connection is not None:
            connection.rollback()
        raise
    finally:
        if connection is not None:
            connection.close()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
