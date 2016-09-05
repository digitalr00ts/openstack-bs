# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "keystone/map.jinja" import server with context %}
{%- if server.enabled %}

keystone_packages:
  pkg.installed:
  - names: {{ server.pkgs }}
  - require:
    - file: keystone_file_override


{%- endif %}
