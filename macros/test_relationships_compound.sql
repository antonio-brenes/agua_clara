{% test relationships_compound(model, to, local_columns, field_columns) %}

with invalid_relationships as (
    select child.*
    from {{ model }} as child
    left join {{ to }} as parent
        on {% for local_column in local_columns %}
            child.{{ local_column }} = parent.{{ field_columns[loop.index0] }}
            {% if not loop.last %}and{% endif %}
        {% endfor %}
    where {% for local_column in local_columns %}
        child.{{ local_column }} is not null
        {% if not loop.last %}and{% endif %}
    {% endfor %}
    and parent.{{ field_columns[0] }} is null
)

select *
from invalid_relationships

{% endtest %}