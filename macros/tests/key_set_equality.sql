{% test key_set_equality(model, compare_model, model_columns, compare_columns) %}

{#
  Valida igualdad bidireccional entre dos conjuntos de claves.
  Devuelve las claves presentes solo en uno de los dos modelos.

  Requisitos:
    - model_columns y compare_columns deben tener la misma longitud.
    - El orden de ambas listas debe representar la misma clave funcional.
#}

{% if model_columns | length != compare_columns | length %}
    {{ exceptions.raise_compiler_error(
        "key_set_equality requiere el mismo numero de model_columns y compare_columns"
    ) }}
{% endif %}

with model_keys as (
    select distinct
        {% for column in model_columns %}
        {{ adapter.quote(column) }} as key_{{ loop.index }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from {{ model }}
),

compare_keys as (
    select distinct
        {% for column in compare_columns %}
        {{ adapter.quote(column) }} as key_{{ loop.index }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from {{ compare_model }}
),

only_in_model as (
    select 'ONLY_IN_MODEL' as difference_type, *
    from model_keys
    minus
    select 'ONLY_IN_MODEL' as difference_type, *
    from compare_keys
),

only_in_compare as (
    select 'ONLY_IN_COMPARE' as difference_type, *
    from compare_keys
    minus
    select 'ONLY_IN_COMPARE' as difference_type, *
    from model_keys
)

select * from only_in_model
union all
select * from only_in_compare

{% endtest %}
