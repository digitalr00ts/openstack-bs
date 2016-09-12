# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "openstack/map.jinja" import server with context %}

# TO DO: add jinja and ServerName to apache2.conf
# TO DO: rm -f /var/lib/keystone/keystone.db

{% set keystone = server.service.keystone %}

include:
  - apache.mod_wsgi
  - ..packages

keystone_file_override:
  file.managed:
    - name: /etc/init/keystone.override
    - user: root
    - group: root
    - mode: 644
    - contents: manual
    - require_in:
      - pkg: os_packages_keystone

keystone_file_conf:
  ini.options_present:
    - name: /etc/keystone/keystone.conf
    - sections:
        DEFAULT:
          admin_token: {{ keystone.service_token }}
        database:
          connection: {{ keystone.database.engine }}://{{ keystone.database.user }}:{{ keystone.database.password }}@{{ keystone.database.host }}/{{ keystone.database.name }}
        {%- if keystone.cache is defined %}
        {%- if keystone.cache.members is defined %}
        memcache:
          servers: {%- for member in keystone.cache.members %}{{ member.host }}:{{ member.port }}{% if not loop.last %},{% endif %}{%- endfor %}
        {%- else %}
        memcache:
          servers: {{ keystone.cache.host }}:{{ keystone.cache.port }}
        {%- endif %}
        token:
          provider: uuid
          driver: memcache
        {%- endif %}
        # Should add check that server.database.engine contains mysql
        revoke:
          driver: sql
    - require:
      - pkg: os_packages_keystone

keystone_file_apache:
  file.managed:
    - name: /etc/apache2/sites-available/wsgi-keystone.conf
    - source: salt://openstack/keystone/files/mitaka/apache_keystone_conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: mod_wsgi

keystone_file_apache_enable:
  file.symlink:
    - name: /etc/apache2/sites-enabled/wsgi-keystone.conf
    - target: /etc/apache2/sites-available/wsgi-keystone.conf
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - module: apache-reload
    - require:
      - file: keystone_file_apache

{%- from "keystone/map.jinja" import server with context %}

# /root/keystonerc:
#   file.managed:
#   - source: salt://keystone/files/keystonerc
#   - template: jinja
#
/root/keystonercv3:
  file.managed:
  - source: salt://openstack/keystone/files/keystonercv3
  - template: jinja
