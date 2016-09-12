# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "openstack/map.jinja" import server with context %}

include:
  - .client
{% if server.service is defined %}

{% for service in server.get('service', {}) %}
{%- if server.service.keystone.enabled %}
  - .{{ service }}
{%- endif %}
{% endfor %}

{% if server.domain is defined %}
  - .domain
{%- endif %}

{%- endif %}
