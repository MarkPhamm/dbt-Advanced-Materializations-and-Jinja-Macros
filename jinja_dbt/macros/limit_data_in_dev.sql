{%- macro limit_data_in_dev(column_name = 'time_stamp', dev_day_of_data = 3) -%}
{%- if target.name == 'dev' -%}
where {{column_name}} >= dateadd('day', -{{dev_day_of_data}}, current_timestamp)
{%- endif -%}
{%- endmacro -%}

{{limit_data_in_dev()}}