
with base as (

    select * 
    from {{ ref('stg_zendesk__ticket_tag_tmp') }}

),

fields as (

    select
        /*
        The below macro is used to generate the correct SQL for package staging models. It takes a list of columns 
        that are expected/needed (staging_columns from dbt_zendesk_source/models/tmp/) and compares it with columns 
        in the source (source_columns from dbt_zendesk_source/macros/).
        For more information refer to our dbt_fivetran_utils documentation (https://github.com/fivetran/dbt_fivetran_utils.git).
        */
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_zendesk__ticket_tag_tmp')),
                staging_columns=get_ticket_tag_columns()
            )
        }}
        
        {{ zendesk_source.apply_source_relation() }}

    from base
),

final as (
    
    select 
        ticket_id,
        {% if target.type == 'redshift' %}
        "tag"
        {% else %}
        tag
        {% endif %} as tags,
        source_relation

    from fields
)

select * 
from final
