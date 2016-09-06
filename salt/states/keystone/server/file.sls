# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "keystone/map.jinja" import server with context %}

include:
  - apache.mod_wsgi

keystone_file_override:
  file.managed:
    - name: /etc/init/keystone.override
    - user: root
    - group: root
    - mode: 644
    - contents: manual
    - require_in:
      - pkg: keystone_packages

keystone_file_conf:
  ini.options_present:
    - name: /etc/keystone/keystone.conf
    - sections:
        DEFAULT:
          admin_token: {{ server.service_token }}
        database:
          connection: {{ server.database.engine }}://{{ server.database.user }}:{{ server.database.password }}@{{ server.database.host }}/{{ server.database.name }}
        {%- if server.cache is defined %}
        {%- if server.cache.members is defined %}
        memcache:
          servers: {%- for member in server.cache.members %}{{ member.host }}:{{ member.port }}{% if not loop.last %},{% endif %}{%- endfor %}
        {%- else %}
        memcache:
          servers: {{ server.cache.host }}:{{ server.cache.port }}
        {%- endif %}
        token:
          provider: uuid
          driver: memcache
        {%- endif %}
        # Should add check that server.database.engine contains mysql
        revoke:
          driver: sql

keystone_file_apache:
  file.managed:
    - name: /etc/apache2/sites-available/wsgi-keystone.conf
    - source: salt://keystone/server/files/apache_keystone_conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: mod_wsgi
    - watch_in:
      - module: apache-reload

keystone_file_apache_enable:
  file.symlink:
    - name: /etc/apache2/sites-enabled/wsgi-keystone.conf
    - target: /etc/apache2/sites-available/wsgi-keystone.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: keystone_file_apache
