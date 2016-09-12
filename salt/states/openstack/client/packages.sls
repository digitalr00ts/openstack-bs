# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "openstack/client/map.jinja" import client with context %}

{% if client.pkgs is defined %}
os_client_client_packages:
  pkg.installed:
    - names: {{ client.pkgs }}
{%- endif %}

{% for service, opts in client.get('service', {}).iteritems() %}
# Will install client packages if client or server for service is enabled
{% if
  (opts.enabled is defined and opts.enabled) or
  (pillar.openstack.server is defined and pillar.openstack.server[service] is defined and
    pillar.openstack.server[ service ].enabled is defined and pillar.openstack.server[ service ].enabled)
%}

os_client_{{ service }}_packages:
  pkg.installed:
    - names: {{ opts.pkgs }}
{% if client.pkgs is defined %}
    - require:
      - pkg: os_client_client_packages
{%- endif %}

{%- endif %}
{% endfor %}
