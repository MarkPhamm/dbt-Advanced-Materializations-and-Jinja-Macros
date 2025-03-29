{#  
    -- let's develop a macro that 
    1. queries the information schema of a database
    2. finds objects that are > 1 week old (no longer maintained)
    3. generates automated drop statements
    4. has the ability to execute those drop statements

#}

{% macro clean_stale_models(database=target.database, schema=target.schema, days=7, dry_run=True) %}
    
    {% set get_drop_commands_query %}
        select
            case 
                when table_type = 'VIEW'
                    then table_type
                else 
                    'TABLE'
            end as drop_type, 
            'DROP ' || drop_type || ' {{ database | upper }}.' || table_schema || '.' || table_name || ';'
        from {{ database }}.information_schema.tables 
        where table_schema = upper('{{ schema }}')
        and last_altered <= current_date - {{ days }} 
    {% endset %}

    {{ log('\nGenerating cleanup queries...\n', info=True) }}
    
    {% set results = run_query(get_drop_commands_query) %}
    
    {% if results is not none %}
        {% set drop_queries = [] %}
        {% for row in results %}
            {% do drop_queries.append(row[1]) %}
        {% endfor %}
        
        {% if drop_queries|length == 0 %}
            {{ log('No stale models found to clean up.', info=True) }}
        {% else %}
            {% for query in drop_queries %}
                {% if dry_run %}
                    {{ log(query, info=True) }}
                {% else %}
                    {{ log('Dropping object with command: ' ~ query, info=True) }}
                    {% do run_query(query) %} 
                {% endif %}       
            {% endfor %}
        {% endif %}
    {% else %}
        {{ log('Error: Could not query information schema. Please check your database connection and permissions.', info=True) }}
    {% endif %}
    
{% endmacro %} 