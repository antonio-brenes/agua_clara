"""Genera los modelos, tests y documentación de la capa l4_fact."""

from __future__ import annotations

import re
from pathlib import Path

import yaml


BASE_DIR = Path(__file__).resolve().parents[1]
DDL_PATH = BASE_DIR / "ddl" / "DDL_AGUA_CLARA.sql"
RAW_SOURCES_PATH = BASE_DIR / "models" / "raw_sicab" / "sources.yml"
L4_DIR = BASE_DIR / "models" / "l4_fact"
L4_DIR.mkdir(parents=True, exist_ok=True)


TABLE_DESCRIPTIONS = {
    "l4_codificacions": "Maestro de códigos funcionales utilizados por el sistema de facturación.",
    "l4_municipi_sgab": "Maestro de municipios y parámetros territoriales de SICAB.",
    "l4_dte_municipal": "Maestro de distritos o demarcaciones municipales.",
    "l4_epigraf_iae": "Maestro de epígrafes de actividades económicas IAE.",
    "l4_carrer": "Maestro de calles del municipio.",
    "l4_finca": "Maestro de fincas y sus datos de localización y lectura.",
    "l4_ramal": "Maestro de ramales o acometidas de suministro.",
    "l4_submin_servei": "Maestro de contratos o suministros de agua y sus características.",
    "l4_submin_iae": "Relación entre suministros y sus epígrafes de actividad económica.",
    "l4_padro_trr": "Padrón de la tasa de residuos asociado a los suministros.",
    "l4_padro_tamgrem": "Padrón de TAMGREM y sus parámetros de cálculo por suministro.",
    "l4_hist_ss_pe": "Histórico de periodos de vulnerabilidad o protección social.",
    "l4_servei_eq_ci": "Equipamiento de servicios contra incendios asociado al suministro.",
    "l4_servei_facturar": "Calendario y cantidades de servicios contra incendios a facturar.",
    "l4_conveni_frau": "Suministros incluidos en convenios o situaciones de fraude.",
    "l4_fact_resum": "Cabecera y resumen económico de las facturas.",
    "l4_fact_aigua": "Desglose de consumos, bloques e importes de agua de cada factura.",
    "l4_fact_concepte": "Líneas de conceptos e importes asociados a cada factura.",
    "l4_fact_regul": "Detalle de regularizaciones de facturación; actualmente fuera del alcance del piloto.",
    "l4_fact_recup": "Detalle de recuperaciones de facturación; actualmente fuera del alcance del piloto.",
    "l4_situacio_fact": "Histórico de transiciones de estado de las facturas.",
    "l4_tarifa_facturacio": "Tabla auxiliar de tarifas y periodos de vigencia de facturación.",
}


FIELD_DESCRIPTIONS = {
    "TIP_CODI": "Tipo de código del catálogo.",
    "CLAU_CODI": "Clave de código del catálogo.",
    "DESC_CODI": "Descripción completa del código.",
    "DESC_BREU": "Descripción abreviada del código.",
    "POLISSA_SUBM": "Identificador de la póliza o suministro.",
    "POLISSA_RAMAL": "Identificador del ramal o acometida.",
    "ID_EMPRESA": "Identificador de la empresa suministradora.",
    "ANY_FACTURA": "Año de la factura.",
    "NUM_FACTURA": "Número secuencial de la factura.",
    "NUM_PARTICIO": "Número de partición de la factura.",
    "NUM_LINEA": "Número de línea dentro de la factura.",
    "NUM_CONCEPTE": "Código del concepto facturado.",
    "IMP_TOTAL_FACT": "Importe total de la factura.",
    "IMP_CONCEPTE": "Importe final de la línea de concepto.",
    "FECHA_EXTRACCION": "Fecha de extracción del registro en RAW.",
    "FECHA_CARGA": "Fecha y hora de carga del registro en la capa L4.",
    "SISTEMA_ORIGEN": "Sistema que originó el registro.",
    "TABLA_ORIGEN": "Tabla RAW de procedencia del registro.",
}


def source_metadata() -> dict[str, dict]:
    source_document = yaml.safe_load(RAW_SOURCES_PATH.read_text(encoding="utf-8"))
    source = next(item for item in source_document["sources"] if item["name"] == "raw_sicab")
    return {table["name"]: table for table in source.get("tables", [])}


def existing_l4_metadata() -> tuple[dict[str, str], dict[str, dict[str, str]]]:
    schema_path = L4_DIR / "schema.yml"
    if not schema_path.exists():
        return {}, {}
    document = yaml.safe_load(schema_path.read_text(encoding="utf-8")) or {}
    table_descriptions = {}
    column_descriptions = {}
    for model in document.get("models", []):
        table_descriptions[model["name"]] = model.get("description", "")
        column_descriptions[model["name"]] = {
            column["name"]: column.get("description", "")
            for column in model.get("columns", [])
        }
    return table_descriptions, column_descriptions


TOKEN_TRANSLATIONS = {
    "NUM": "número", "NOMB": "número", "NOMBRE": "nombre", "ID": "identificador",
    "DATA": "fecha", "FECHA": "fecha", "ANY": "año", "MES": "mes", "DIA": "día",
    "MOM": "instante", "TS": "marca temporal", "TIP": "tipo", "SIT": "situación",
    "DESC": "descripción", "NOM": "nombre", "CODI": "código", "CLAU": "clave",
    "IMP": "importe", "BASE": "base", "PREU": "precio", "PERC": "porcentaje",
    "M3": "metros cúbicos", "BLOC": "bloque", "FACT": "factura", "SERV": "servicio",
    "SUBM": "suministro", "MUN": "municipio", "CARRER": "calle", "DTE": "distrito",
    "FINCA": "finca", "RAMAL": "ramal", "IAE": "IAE", "PADRO": "padrón",
    "HIST": "histórico", "CONCEPTE": "concepto", "AIGUA": "agua", "TAXA": "tasa",
    "QUOTA": "cuota", "ORIGEN": "origen", "CARGA": "carga", "EMPRESA": "empresa",
    "CLIENT": "cliente",
}


def field_description(column: str, raw_name: str, source_tables: dict[str, dict]) -> str:
    source_columns = {
        item["name"]: item.get("description", "")
        for item in source_tables.get(raw_name, {}).get("columns", [])
    }
    if source_columns.get(column):
        return source_columns[column]
    if column in FIELD_DESCRIPTIONS:
        return FIELD_DESCRIPTIONS[column]
    words = [TOKEN_TRANSLATIONS.get(word, word.lower()) for word in column.split("_")]
    return "Campo de " + " ".join(words) + "."


def parse_l4_tables() -> tuple[
    dict[str, list[tuple[str, str]]],
    dict[str, list[str]],
    dict[str, set[str]],
    dict[str, list[tuple[list[str], str, list[str]]]],
]:
    ddl = DDL_PATH.read_text(encoding="utf-8")
    tables: dict[str, list[tuple[str, str]]] = {}
    primary_keys: dict[str, list[str]] = {}
    not_null_columns: dict[str, set[str]] = {}
    pattern = re.compile(
        r"CREATE OR REPLACE TABLE (L4_[A-Z0-9_]+) \((.*?)\n\s*\n?\);",
        re.DOTALL,
    )
    for match in pattern.finditer(ddl):
        columns: list[tuple[str, str]] = []
        not_null_columns[match.group(1)] = set()
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
                if re.search(r"\bNOT\s+NULL\b", line):
                    not_null_columns[match.group(1)].add(column.group(1))
        tables[match.group(1)] = columns

    foreign_keys: dict[str, list[tuple[list[str], str, list[str]]]] = {}
    foreign_key_pattern = re.compile(
        r"ALTER TABLE\s+(L4_[A-Z0-9_]+).*?FOREIGN KEY\s*\((.*?)\)\s*"
        r"REFERENCES\s+(L4_[A-Z0-9_]+)\s*\((.*?)\)",
        re.DOTALL,
    )
    for match in foreign_key_pattern.finditer(ddl):
        local_columns = re.findall(r"[A-Z][A-Z0-9_]*", match.group(2))
        referenced_columns = re.findall(r"[A-Z][A-Z0-9_]*", match.group(4))
        foreign_keys.setdefault(match.group(1), []).append(
            (local_columns, match.group(3), referenced_columns)
        )
    return tables, primary_keys, not_null_columns, foreign_keys


def raw_sources() -> list[str]:
    sources = RAW_SOURCES_PATH.read_text(encoding="utf-8")
    return re.findall(r"^      - name: (raw_[a-z0-9_]+)$", sources, re.MULTILINE)


def expression(
    column: str,
    data_type: str,
    source_columns: set[str],
    mandatory_columns: set[str],
) -> str:
    mandatory = column in mandatory_columns
    if column not in source_columns:
        value = f"CAST(NULL AS {data_type})"
    else:
        raw = f'NULLIF(TRIM(raw."{column}"), \'\')'
        if data_type == "DATE":
            value = f"TRY_TO_DATE({raw})"
        elif data_type.startswith("TIMESTAMP"):
            value = f"TRY_TO_TIMESTAMP_NTZ({raw})"
        elif data_type.startswith("NUMBER"):
            number_parts = data_type.removeprefix("NUMBER(").removesuffix(")").split(",")
            precision = number_parts[0]
            scale = number_parts[1] if len(number_parts) > 1 else "0"
            value = f"TRY_TO_DECIMAL({raw}, {precision}, {scale})"
        else:
            value = raw

    if mandatory:
        if data_type == "DATE":
            value = f"COALESCE({value}, '0001-01-01'::DATE)"
        elif data_type.startswith("TIMESTAMP"):
            value = (
                f"COALESCE({value}, "
                "'0001-01-01 00:00:00.000'::TIMESTAMP_NTZ)"
            )
        elif data_type.startswith("NUMBER"):
            value = f"COALESCE({value}, 0)"
        else:
            value = f"COALESCE({value}, '^^')"

    return f"{value} AS {column}"


tables, primary_keys, not_null_columns, foreign_keys = parse_l4_tables()
source_tables = source_metadata()
existing_table_descriptions, existing_column_descriptions = existing_l4_metadata()
available_sources = set(source_tables) or set(raw_sources())
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
    mandatory_columns = not_null_columns.get(table_name, set())
    select_expressions = [
        expression(name, data_type, source_columns, mandatory_columns)
        for name, data_type in columns
    ]
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
            "DATEDIFF('millisecond', '1970-01-01'::TIMESTAMP_TZ, '{{ run_started_at.isoformat() }}'::TIMESTAMP_TZ) AS ID_CARGA",
            f"{extraction_expression} AS FECHA_EXTRACCION",
            "CONVERT_TIMEZONE('Europe/Madrid', CURRENT_TIMESTAMP()) AS FECHA_CARGA",
            f"{origin_expression} AS SISTEMA_ORIGEN",
            f"'RAW_{l4_name.upper()}' AS TABLA_ORIGEN",
        ]
    )
    sql = """{{{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key={unique_key},
    schema='l4_fact',
    tags=['l4_fact', 'l4', 'bronze']
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
        unique_key=repr(primary_keys.get(table_name, [columns[0][0]])),
        source_relation=source_relation,
        select_list=",\n    ".join(select_expressions),
    )
    (L4_DIR / f"{model_name}.sql").write_text(sql, encoding="utf-8")
    generated.append(model_name)

    schema_lines.append(f"  - name: {model_name}")
    schema_lines.append(
        f'    description: "{existing_table_descriptions.get(model_name) or source_tables.get(raw_name, {}).get("description") or TABLE_DESCRIPTIONS.get(model_name, "Entidad L4 del dominio de facturación de Agua Clara.")}"'
    )
    schema_lines.append("    tests:")
    schema_lines.append("      - dbt_utils.unique_combination_of_columns:")
    schema_lines.append("          arguments:")
    schema_lines.append("            combination_of_columns:")
    for key_column in primary_keys.get(table_name, [columns[0][0]]):
        schema_lines.append(f"              - {key_column}")
    for local_columns, referenced_table, referenced_columns in foreign_keys.get(table_name, []):
        referenced_model = f"l4_{referenced_table.removeprefix('L4_').lower()}"
        schema_lines.extend(
            [
                "      - relationships_compound:",
                "          arguments:",
                f'            to: "{{{{ ref(\'{referenced_model}\') }}}}"',
                f"            local_columns: [{', '.join(local_columns)}]",
                f"            field_columns: [{', '.join(referenced_columns)}]",
            ]
        )
    schema_lines.append("    columns:")
    for name, data_type in columns:
        schema_lines.append(f"      - name: {name}")
        schema_lines.append(f"        data_type: {data_type.lower()}")
        description = existing_column_descriptions.get(model_name, {}).get(name)
        if not description:
            description = field_description(name, raw_name, source_tables)
        schema_lines.append(f'        description: "{description}"')
        if name in not_null_columns.get(table_name, set()):
            schema_lines.append("        tests:")
            schema_lines.append("          - not_null")
    schema_lines.extend(
        [
            '      - name: ID_CARGA\n        data_type: number\n        description: "Identificador técnico del lote o ejecución que incorporó el registro."',
            '      - name: FECHA_EXTRACCION\n        data_type: timestamp_tz\n        description: "Fecha de extracción del registro en RAW."',
            '      - name: FECHA_CARGA\n        data_type: timestamp_tz\n        description: "Fecha y hora de carga normalizada a Europe/Madrid."',
            '      - name: SISTEMA_ORIGEN\n        data_type: varchar(30)\n        description: "Sistema de origen heredado de RAW."',
            '      - name: TABLA_ORIGEN\n        data_type: varchar(50)\n        description: "Tabla RAW de procedencia."',
        ]
    )
    schema_lines.append("")

(L4_DIR / "schema.yml").write_text("\n".join(schema_lines).rstrip() + "\n", encoding="utf-8")
print(f"Generated {len(generated)} l4_fact models, tests metadata and documentation")