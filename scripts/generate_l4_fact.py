"""Genera los modelos, tests y documentación de la capa l4_fact."""

from __future__ import annotations

import re
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[1]
DDL_PATH = BASE_DIR / "ddl" / "DDL_AGUA_CLARA.sql"
RAW_SOURCES_PATH = BASE_DIR / "models" / "agua_clara" / "raw_sicab" / "sources.yml"
L4_DIR = BASE_DIR / "models" / "agua_clara" / "l4_fact"
L4_DIR.mkdir(parents=True, exist_ok=True)


def parse_l4_tables() -> tuple[dict[str, list[tuple[str, str]]], dict[str, list[str]]]:
    ddl = DDL_PATH.read_text(encoding="utf-8")
    tables: dict[str, list[tuple[str, str]]] = {}
    primary_keys: dict[str, list[str]] = {}
    pattern = re.compile(
        r"CREATE OR REPLACE TABLE (L4_[A-Z0-9_]+) \((.*?)\n\s*\n?\);",
        re.DOTALL,
    )
    for match in pattern.finditer(ddl):
        columns: list[tuple[str, str]] = []
        primary_key_match = re.search(r"PRIMARY KEY\s*\((.*?)\)", match.group(2), re.DOTALL)
        if primary_key_match:
            primary_keys[match.group(1)] = re.findall(r"[A-Z][A-Z0-9_]*", primary_key_match.group(1))
        for line in match.group(2).splitlines():
            line = line.strip()
            if line.startswith(("CONSTRAINT", "PRIMARY KEY", "FOREIGN KEY")):
                continue
            column = re.match(r"([A-Z][A-Z0-9_]*)\s+([A-Z]+(?:\([0-9,]+\))?)", line)
            if column and column.group(1) not in {"CONSTRAINT"}:
                columns.append((column.group(1), column.group(2)))
        tables[match.group(1)] = columns
    return tables, primary_keys


def raw_sources() -> list[str]:
    sources = RAW_SOURCES_PATH.read_text(encoding="utf-8")
    return re.findall(r"^      - name: (raw_[a-z0-9_]+)$", sources, re.MULTILINE)


def expression(column: str, data_type: str, source_columns: set[str]) -> str:
    if column not in source_columns:
        return f"CAST(NULL AS {data_type}) AS {column}"
    raw = f'NULLIF(TRIM(raw."{column}"), \'\')'
    if data_type == "DATE":
        return f"TRY_TO_DATE({raw}) AS {column}"
    if data_type.startswith("TIMESTAMP"):
        return f"TRY_TO_TIMESTAMP_NTZ({raw}) AS {column}"
    if data_type.startswith("NUMBER"):
        number_parts = data_type.removeprefix("NUMBER(").removesuffix(")").split(",")
        precision = number_parts[0]
        scale = number_parts[1] if len(number_parts) > 1 else "0"
        return f"TRY_TO_DECIMAL({raw}, {precision}, {scale}) AS {column}"
    return f"{raw} AS {column}"


tables, primary_keys = parse_l4_tables()
available_sources = set(raw_sources())
generated: list[str] = []
schema_lines = ["version: 2", "", "models:"]

for table_name, columns in tables.items():
    l4_name = table_name.removeprefix("L4_").lower()
    raw_name = f"raw_{l4_name}"
    columns = [
        (name, data_type)
        for name, data_type in columns
        if name not in {"ID_CARGA", "FECHA_EXTRACCION", "FECHA_CARGA", "SISTEMA_ORIGEN", "TABLA_ORIGEN"}
    ]

    model_name = f"l4_{l4_name}"
    csv_path = BASE_DIR / "datos" / f"{l4_name}.csv"
    source_columns: set[str] = set()
    if csv_path.exists():
        import csv

        with csv_path.open("r", encoding="latin-1", newline="") as source_file:
            sample = source_file.read(4096)
            source_file.seek(0)
            quotechar = '"' if '"' in sample else None
            source_columns = {
                name.strip().replace(" ", "_").replace("-", "_").replace("/", "_").replace(".", "")
                for name in next(csv.reader(source_file, delimiter=";", quotechar=quotechar), [])
            }
    select_expressions = [expression(name, data_type, source_columns) for name, data_type in columns]
    source_relation = (
        f"from {{{{ source('raw_sicab', '{raw_name}') }}}}"
        if raw_name in available_sources
        else "from (select 1 as placeholder where false)"
    )
    extraction_expression = (
        "raw.FECHA_EXTRACCION"
        if raw_name in available_sources
        else "CAST(NULL AS TIMESTAMP_NTZ)"
    )
    origin_expression = (
        "raw.SISTEMA_ORIGEN"
        if raw_name in available_sources
        else "CAST(NULL AS VARCHAR(30))"
    )
    select_expressions.extend(
        [
            "DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_NTZ, raw.FECHA_EXTRACCION) AS ID_CARGA",
            f"{extraction_expression} AS FECHA_EXTRACCION",
            "CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS FECHA_CARGA",
            f"{origin_expression} AS SISTEMA_ORIGEN",
            f"'RAW_{l4_name.upper()}' AS TABLA_ORIGEN",
        ]
    )
    sql = """{{{{ config(
    materialized='table',
    schema='l4_fact',
    tags=['l4_fact']
) }}}}

with raw as (
    select *
    {source_relation}
)

select
    {select_list}
from raw
""".format(
        raw_name=raw_name,
        source_relation=source_relation,
        select_list=",\n    ".join(select_expressions),
    )
    (L4_DIR / f"{model_name}.sql").write_text(sql, encoding="utf-8")
    generated.append(model_name)

    schema_lines.append(f"  - name: {model_name}")
    schema_lines.append(f'    description: "Modelo L4 tipado a partir de {raw_name}."')
    schema_lines.append("    tests:")
    schema_lines.append("      - dbt_utils.unique_combination_of_columns:")
    schema_lines.append("          arguments:")
    schema_lines.append("            combination_of_columns:")
    for key_column in primary_keys.get(table_name, [columns[0][0]]):
        schema_lines.append(f"              - {key_column}")
    schema_lines.append("    columns:")
    schema_lines.append("      - name: FECHA_EXTRACCION")
    schema_lines.append('        description: "Fecha y hora de extracción heredada de RAW."')
    schema_lines.append("        tests:")
    schema_lines.append("          - not_null")
    for name, _ in columns:
        schema_lines.append(f'      - name: {name}\n        description: "Campo tipado de {raw_name}."')
    schema_lines.extend(
        [
            '      - name: ID_CARGA\n        description: "Identificador técnico de la carga."',
            '      - name: FECHA_CARGA\n        description: "Fecha y hora de carga normalizada a Europe/Madrid."',
            '      - name: SISTEMA_ORIGEN\n        description: "Sistema de origen heredado de RAW."',
            '      - name: TABLA_ORIGEN\n        description: "Tabla RAW de procedencia."',
        ]
    )
    schema_lines.append("")

(L4_DIR / "schema.yml").write_text("\n".join(schema_lines).rstrip() + "\n", encoding="utf-8")
print(f"Generated {len(generated)} l4_fact models, tests metadata and documentation")