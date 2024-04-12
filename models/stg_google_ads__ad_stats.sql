{{ config(enabled=var('ad_reporting__google_ads_enabled', True)) }}

with base as (

    select * 
    from {{ ref('stg_google_ads__ad_stats_tmp') }}

),

fields as (

    select
        *,
        cast(null as string) as ad_group,
        cast(null as string) as keyword_ad_group_criterion        
    
        {{ fivetran_utils.source_relation(
            union_schema_variable='google_ads_union_schemas', 
            union_database_variable='google_ads_union_databases') 
        }}

    from base
),

final as (

    select
        source_relation, 
        customer_id as account_id, 
        date as date_day, 
        {% if target.type in ('spark','databricks') %}
        coalesce(cast(ad_group_id as {{ dbt.type_string() }}), split(ad_group,'adGroups/')[1]) as ad_group_id,
        {% else %}
        coalesce(cast(ad_group_id as {{ dbt.type_string() }}), {{ dbt.split_part(string_text='ad_group', delimiter_text="'adGroups/'", part_number=2) }}) as ad_group_id,
        {% endif %}
        keyword_ad_group_criterion,
        ad_network_type,
        device,
        ad_id, 
        campaign_id, 
        clicks, 
        cost_micros / 1000000.0 as spend, 
        impressions,
        conversions
        
        {{ fivetran_utils.fill_pass_through_columns('google_ads__ad_stats_passthrough_metrics') }}

    from fields
)

select * from final
