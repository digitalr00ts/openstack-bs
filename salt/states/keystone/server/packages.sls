# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "keystone/map.jinja" import server with context %}

include:
  - mysql.python
  - mysql.client
  - memcached.python_memcached

keystone_packages:
  pkg.installed:
  - names: {{ server.pkgs }}
  - require:
    - pkg: mysql_python
    - pkg: mysql
    - pkg: python-memcached
    - file: keystone_file_override
