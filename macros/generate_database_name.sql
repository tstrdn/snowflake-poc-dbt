{#
    The companion to generate_schema_name, and necessary for the same reason.

    Seeds are configured with `+database: RAW` so that in a deployed
    environment they land where an ingestion tool would write. But for the
    sandbox and CI targets everything must collapse into the one throwaway
    location named by the target - otherwise seeds aim at RAW while models aim
    at ANALYTICS, the run needs CREATE SCHEMA on two databases, and teardown
    only cleans up one of them.

    Overriding the schema alone is not enough: dbt resolves database and schema
    independently, so a custom database survives a custom schema being ignored.
#}

{% macro generate_database_name(custom_database_name, node) -%}

    {%- set isolated_targets = ["ci", "sandbox"] -%}

    {%- if target.name in isolated_targets or custom_database_name is none -%}
        {{ target.database }}
    {%- else -%}
        {{ custom_database_name | trim }}
    {%- endif -%}

{%- endmacro %}
