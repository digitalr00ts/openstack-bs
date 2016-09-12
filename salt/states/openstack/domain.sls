# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "openstack/map.jinja" import server with context %}

include:
  - .keystone.file

os_roles:
  keystone.role_present:
  - names: {{ server.roles }}

{% for domain, param in server.get('domain', {}).iteritems() %}

os_domain_{{ domain }}:
  cmd.run:
    - name: source /root/keystonercv3 && openstack domain create --description "{{ param.description }}" {{ domain }}
    - unless: source /root/keystonercv3 && openstack domain list | grep " {{ domain }}"
    - require:
      - file: /root/keystonercv3

{%- for tenant_name, tenant in param.get('tenant', {}).iteritems() %}

os_tenant_{{ domain }}_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
  - require:
    - keystone: os_roles

{% if tenant.user is defined %}
{%- for user_name, user in tenant.get('user', {}).iteritems() %}

os_user_{{ domain }}_{{ user_name }}:
  keystone.user_present:
  - name: {{ user_name }}
  - password: {{ user.password }}
  - email: {{ user.get('email', 'root@localhost') }}
  - tenant: {{ tenant_name }}
  - roles:
    {{ tenant_name }}:
    {%- if user.get('roles', False) %}
      {{ user.roles }}
    {%- else %}
      - user
    {%- endif %}
  - require:
    - keystone: os_tenant_{{ domain }}_{{ tenant_name }}

{%- endfor %}
{% endif %}

{%- endfor %}

{% endfor %}
