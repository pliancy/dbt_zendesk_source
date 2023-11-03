--To disable this model, set the using_user_tags variable within your dbt_project.yml file to False.
{{ config(enabled=var('using_user_tags', True)) }}

select {{ dbt_utils.star(from=source('zendesk', 'user_tag')) }}  
from {{ var('user_tag') }}
