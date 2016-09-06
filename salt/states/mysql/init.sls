# -*- coding: utf-8 -*-
# vim: ft=sls

{% from 'mysql/database.sls' import db_states with context %}
{% from 'mysql/user.sls' import user_states with context %}

{% macro requisites(type, states) %}
      {%- for state in states %}
        - {{ type }}: {{ state }}
      {%- endfor -%}
{% endmacro %}

include:
  - mysql.server
  - mysql.database
  - mysql.user

{#
{% if (db_states|length() + user_states|length()) > 0 %}
extend:
  mysqld:
    #service:
    cmd:
      - require_in:
        {{ requisites('mysql_database', db_states) }}
        {{ requisites('mysql_user', user_states) }}
{% endif %}
#}
