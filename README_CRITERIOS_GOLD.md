# Gold Fact corregido

Paquete de referencia generado conforme a CRITERIOS GOLD.

## Instalacion
1. Copiar `models/gold_fact` a la ruta de modelos del proyecto.
2. Copiar `tests/gold_fact` a la ruta de tests.
3. Copiar `seeds/gold_fact/g_s_concepto_clasificacion.csv`.
4. Configurar el seed en `dbt_project.yml` y ejecutar `dbt seed --full-refresh --select g_s_concepto_clasificacion`.
5. Ejecutar `dbt compile --select tag:gold_fact`, `dbt run --select tag:gold_fact` y `dbt test --select tag:gold_fact`.

## Nota
Las vistas materializadas para perspectivas bruta, actual y fin de mes no se incluyen porque no se aportaron sus reglas funcionales exactas.
