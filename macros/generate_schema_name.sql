{#
    dbt's default behaviour concatenates the target schema and the custom
    schema, producing ANALYTICS.JAFFLE_STG_JAFFLE_MARTS. The platform's schema
    names are managed by Terraform and must match exactly, so deployed targets
    use the custom schema verbatim.

    Sandbox and CI targets do the opposite: everything collapses into the one
    throwaway schema named by the target, so a developer's work or a pull
    request's models never leak into the shared staging and mart schemas.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set isolated_targets = ["ci", "sandbox"] -%}

    {%- if target.name in isolated_targets or custom_schema_name is none -%}
        {{ target.schema | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
