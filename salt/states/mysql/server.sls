include:
  - mysql.file
  # - mysql.config
  - mysql.python

{% from "mysql/defaults.yaml" import rawmap with context %}
{%- set mysql = salt['grains.filter_by'](rawmap, grain='os', merge=salt['pillar.get']('mysql:lookup')) %}

{% set os = salt['grains.get']('os', None) %}
{% set os_family = salt['grains.get']('os_family', None) %}
{% set mysql_root_user = salt['pillar.get']('mysql:server:root_user', 'root') %}
{% set mysql_root_password = salt['pillar.get']('mysql:server:root_password', salt['grains.get']('server_id')) %}
{% set mysql_host = salt['pillar.get']('mysql:server:host', 'localhost') %}
{% set mysql_salt_user = salt['pillar.get']('mysql:salt_user:salt_user_name', mysql_root_user) %}
{% set mysql_salt_password = salt['pillar.get']('mysql:salt_user:salt_user_password', mysql_root_password) %}

mysql_debconf_utils:
  pkg.installed:
    - name: {{ mysql.debconf_utils }}

mysql_debconf:
  debconf.set:
    - name: {{ mysql.debconf_key }}
    - data:
        '{{ mysql.service }}-server/root_password_again': {'type': 'password', 'value': '{{ mysql_root_password }}'}
        '{{ mysql.service }}-server/root_password': {'type': 'password', 'value': '{{ mysql_root_password }}'}
    - require:
      - pkg: mysql_debconf_utils

mysqld-packages:
  pkg.installed:
    - name: {{ mysql.server }}
    - require:
      - file: mysql_file_policy-rc_modify
{% if os_family == 'Debian' and mysql_root_password %}
      - debconf: mysql_debconf
{% endif %}

{% if mysql.server == 'mariadb-server' %}
# Workaround for MariaDB 5.5 init.d bug
mysqld_initd:
  file.line:
    - name: /etc/init.d/mysql
    - content: '/usr/bin/mysqld_safe "${@:2}" >/dev/null 2>&1 | $ERR_LOGGER &'
    - match: '/usr/bin/mysqld_safe "${@:2}" 2>&1 >/dev/null | $ERR_LOGGER &'
    - mode: replace
    - indent: true
    - require:
      - pkg: mysqld-packages
{% endif %}

mysqld:
  service.running:
    - name: {{ mysql.service }}
    - enable: True
    - require:
      - pkg: {{ mysql.server }}
{% if mysql.server == 'mariadb-server' %}
      - file: mysqld_initd
{% endif %}
    - watch:
      - pkg: {{ mysql.server }}
