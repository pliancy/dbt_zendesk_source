{% macro union_zendesk_connections(connection_dictionary, single_source_name, single_table_name) %}

{{ adapter.dispatch('union_zendesk_connections', 'zendesk_source') (connection_dictionary, single_source_name, single_table_name) }}

{%- endmacro %}

{% macro default__union_zendesk_connections(connection_dictionary, single_source_name, single_table_name) %}

{% if connection_dictionary %}
{# For unioning #}
    {%- set relations = [] -%}
    {%- for connection in connection_dictionary -%}

        {%- set relation=adapter.get_relation(
                            database=source(connection.name, single_table_name).database,
                            schema=source(connection.name, single_table_name).schema,
                            identifier=source(connection.name, single_table_name).identifier) if var('has_defined_sources', false)
                            
                    else adapter.get_relation(
                            database=connection.database if connection.database else target.database,
                            schema=connection.schema if connection.schema else single_source_name,
                            identifier=single_table_name
                    ) 
        -%}

        {%- if relation is not none -%}
            {%- do relations.append(relation) -%}
        {%- endif -%}

    {%- endfor -%}

    {%- if relations != [] -%}
        {{ zendesk_source.zendesk_union_relations(relations) }}
    {%- else -%}
        {% if execute and not var('fivetran__remove_empty_table_warnings', false) -%}
        {{ exceptions.warn("\n\nPlease be aware: The " ~ single_source_name ~ "." ~ single_table_name ~ " table was not found in your schema(s). The Fivetran Data Model will create a completely empty staging model as to not break downstream transformations. To turn off these warnings, set the `fivetran__remove_empty_table_warnings` variable to TRUE (see https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union_data-source for details).\n") }}
        {% endif -%}
    select 
        cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
    limit {{ '0' if target.type != 'redshift' else '1' }}
    {%- endif -%}

{% else %}
{# Not unioning #}

    {% set identifier_var = "zendesk_" + single_table_name + "_identifier"%}

    {%- set relation=adapter.get_relation(
        database=source(single_source_name, single_table_name).database,
        schema=source(single_source_name, single_table_name).schema,
        identifier=var(identifier_var, single_table_name)
    ) -%}

    {%- if relation is not none -%}
        select
            {{ dbt_utils.star(from=source(single_source_name, single_table_name)) }}
        from {{ source(single_source_name, single_table_name) }} as source_table
    
    {% else %}
        {% if execute and not var('fivetran__remove_empty_table_warnings', false) -%}
            {{ exceptions.warn("\n\nPlease be aware: The " ~ single_source_name|upper ~ "." ~ single_table_name|upper ~ " table was not found in your schema(s). The Fivetran Data Model will create a completely empty staging model as to not break downstream transformations. To turn off these warnings, set the `fivetran__remove_empty_table_warnings` variable to TRUE (see https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union_data-source for details).\n") }}
        {% endif -%}
        
        select 
            cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
        limit {{ '0' if target.type != 'redshift' else '1' }}
    {%- endif -%}
{% endif -%}

{%- endmacro %}