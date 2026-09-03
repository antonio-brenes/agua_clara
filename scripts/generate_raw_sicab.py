from pathlib import Path
import csv
import re

base = Path(r"C:\Users\abrenes\OneDrive - ALTEN Group\Documents\proyectos\dbt\agua_clara")
datos_dir = base / "datos"
raw_dir = base / "models" / "agua_clara" / "raw_sicab"
raw_dir.mkdir(parents=True, exist_ok=True)
ddl_dir = base / "ddl"
ddl_dir.mkdir(exist_ok=True)

RAW_DATABASE = "DES_AGUA_CLARA"
RAW_SCHEMA = "RAW_SICAB"
RAW_STAGE = "RAW_STAGE"
L4_DDL_PATH = ddl_dir / "DDL_AGUA_CLARA.sql"


def sanitize_col(name: str) -> str:
    value = name.strip().replace(' ', '_').replace('-', '_').replace('/', '_').replace('.', '_')
    value = ''.join(ch for ch in value if ch.isalnum() or ch == '_')
    if not value:
        return 'COLUMN_' + str(len(value) + 1)
    return value


def read_csv_header(csv_path: Path):
    with csv_path.open('r', encoding='latin-1', newline='') as f:
        sample = f.read(4096)
        f.seek(0)
        has_quotes = '"' in sample
        quotechar = '"' if has_quotes else None
        reader = csv.reader(f, delimiter=';', quotechar=quotechar)
        header = next(reader, None)
        return header, has_quotes


def read_l4_columns(table_name: str) -> list[str]:
    ddl = L4_DDL_PATH.read_text(encoding="utf-8")
    match = re.search(
        rf"CREATE OR REPLACE TABLE {table_name} \((.*?)\n\s*\n?\);",
        ddl,
        re.DOTALL,
    )
    if not match:
        raise RuntimeError(f"No se ha encontrado {table_name} en {L4_DDL_PATH}")
    columns = []
    for line in match.group(1).splitlines():
        column = re.match(r"\s*([A-Z][A-Z0-9_]*)\s+[A-Z]+(?:\([0-9,]+\))?", line)
        if column and column.group(1) not in {"CONSTRAINT", "PRIMARY", "FOREIGN"}:
            columns.append(column.group(1))
    return columns


source_entries = []
tables = []
raw_ddl = []
raw_copy = []

for csv_path in sorted(datos_dir.glob('*.csv')):
    header, has_quotes = read_csv_header(csv_path)
    if not header:
        continue

    raw_name = 'raw_' + csv_path.stem
    tables.append(raw_name)
    source_entries.append(f'      - name: {raw_name}\n        description: "Tabla raw de {csv_path.stem}."')

    ddl_columns = [f'    "{sanitize_col(col)}" VARCHAR' for col in header]
    ddl_columns.extend([
        '    FECHA_EXTRACCION TIMESTAMP_NTZ',
        '    SISTEMA_ORIGEN VARCHAR(30)'
    ])
    ddl_sql = (
        f"CREATE OR REPLACE TABLE {raw_name.upper()} (\n"
        + ',\n'.join(ddl_columns)
        + '\n);\n\n'
    )
    raw_ddl.append(ddl_sql)

    copy_columns = ', '.join(f'"{sanitize_col(col)}"' for col in header)
    copy_columns_with_meta = copy_columns + ', FECHA_EXTRACCION, SISTEMA_ORIGEN'
    select_columns = ', '.join(
        f'${idx} AS "{sanitize_col(col)}"' for idx, col in enumerate(header, start=1)
    )
    if has_quotes:
        format_clause = "FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '\"' FIELD_DELIMITER = ';' SKIP_HEADER = 1 NULL_IF = ('', 'NULL'))"
    else:
        format_clause = "FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ';' SKIP_HEADER = 1 NULL_IF = ('', 'NULL'))"
    copy_sql = f'''COPY INTO {raw_name.upper()} ({copy_columns_with_meta})
FROM (
    SELECT
        {select_columns},
        CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_EXTRACCION,
        'SICAB' AS SISTEMA_ORIGEN
    FROM @{RAW_STAGE}/{csv_path.name}
)
{format_clause};

'''
    raw_copy.append(copy_sql)

for empty_table in ("RAW_FACT_REGUL", "RAW_FACT_RECUP"):
    empty_columns = read_l4_columns(empty_table.replace("RAW_", "L4_"))
    source_entries.append(
        f'      - name: {empty_table.lower()}\n'
        f'        description: "Tabla raw vacía de {empty_table.lower()} pendiente de definición de origen."'
    )
    ddl_columns = [f'    "{column}" VARCHAR' for column in empty_columns]
    ddl_columns.extend([
        '    FECHA_EXTRACCION TIMESTAMP_NTZ',
        '    SISTEMA_ORIGEN VARCHAR(30)',
    ])
    raw_ddl.append(
        f"CREATE OR REPLACE TABLE {empty_table} (\n"
        + ",\n".join(ddl_columns)
        + "\n);\n\n"
    )

source_yml = (
    "version: 2\n\n"
    "sources:\n"
    "  - name: raw_sicab\n"
    "    description: \"Tablas RAW de origen SICAB para el piloto Agua Clara\"\n"
    "    database: des_agua_clara\n"
    "    schema: raw_sicab\n"
    "    tables:\n"
    + '\n'.join(source_entries)
    + '\n'
)
(raw_dir / 'sources.yml').write_text(source_yml, encoding='utf-8')

(ddl_dir / 'RAW_SICAB_DDL.sql').write_text(
    f'USE DATABASE {RAW_DATABASE};\nUSE SCHEMA {RAW_SCHEMA};\n\n' + ''.join(raw_ddl),
    encoding='utf-8'
)
(ddl_dir / 'COPY_INTO_RAW_SICAB.sql').write_text(
    f'USE DATABASE {RAW_DATABASE};\nUSE SCHEMA {RAW_SCHEMA};\n\n' + ''.join(raw_copy),
    encoding='utf-8'
)

print(f'Generated DDL and COPY scripts for {len(tables)} RAW tables')
