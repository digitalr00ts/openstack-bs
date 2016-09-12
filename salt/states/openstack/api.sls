# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "openstack/map.jinja" import server with context %}

{% for service, param in server.get('service', {}).iteritems() %}
{% if param.enabled is defined and param.enabled %}

os_api_{{ service }}_service:
  keystone.service_present:
  - name: {{ param.name }}
  - service_type: {{ param.type }}
  - description: {{ param.description }}
#  - require:
#    - keystone: keystone_roles

os_api_{{ service }}_endpoint:
  keystone.endpoint_present:
  - name: {{ param.name }}
  - publicurl: '{{ param.bind.get('public_protocol', 'http') }}://{{ param.bind.public_address }}:{{ param.bind.public_port }}/v{{ server.api_version }}'
  - internalurl: '{{ param.bind.get('internal_protocol', 'http') }}://{{ param.bind.internal_address }}:{{ param.bind.internal_port }}/v{{ server.api_version }}'
  - adminurl: '{{ param.bind.get('admin_protocol', 'http') }}://{{ param.bind.admin_address }}:{{ param.bind.admin_port }}/v{{ server.api_version }}'
  - region: {{ param.get('region', 'RegionOne') }}
  - require:
    - keystone: os_api_{{ service }}_service
  #  - file: keystone_salt_config
{#
{% if service.user is defined %}

keystone_user_{{ service.user.name }}:
  keystone.user_present:
  - name: {{ service.user.name }}
  - password: {{ service.user.password }}
  - email: {{ server.admin_email }}
  - tenant: {{ server.service_tenant }}
  - roles:
      {{ server.service_tenant }}:
      - admin
  - require:
    - keystone: keystone_roles

{% endif %}
#}

{% endif %}
{% endfor %}
{#
keystone_service_tenant:
  keystone.tenant_present:
  - name: {{ server.service_tenant }}
#}
