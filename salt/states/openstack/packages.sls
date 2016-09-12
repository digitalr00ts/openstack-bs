# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "openstack/map.jinja" import server with context %}

{% for service, param in server.get('service', {}).iteritems() %}
{% if param.enabled is defined and param.enabled %}

os_packages_{{ service }}:
  pkg.installed:
  - names: {{ param.pkgs }}

{% endif %}
{% endfor %}
