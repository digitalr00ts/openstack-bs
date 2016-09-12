# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "mysql/defaults.yaml" import rawmap with context %}
{%- set mysql = salt['grains.filter_by'](rawmap, grain='os', merge=salt['pillar.get']('mysql:server:lookup')) %}
{%- from "openstack/map.jinja" import server with context %}

include:
  - mysql.python
  - mysql.user
  - ..packages
  - .file

{%- if not grains.get('noservices', False) %}
keystone_syncdb:
  cmd.wait:
  - name: keystone-manage db_sync; sleep 1
  - watch:
    - ini: keystone_file_conf
  - require:
    - pkg: mysql_python
    {% for name, user in salt['pillar.get']('mysql:user', {}).items() %}
    - mysql_user: {{ name }}
    {% endfor %}
{%- endif %}

{% if server.service.keystone.token.provider == 'fernet' %}
{%- if not grains.get('noservices', False) %}
keystone_fernet_setup:
  cmd.wait:
  - name: keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
  - watch:
    - ini: keystone_file_conf
  - require:
    - pkg: os_packages_keystone
{%- endif %}
{% endif %}