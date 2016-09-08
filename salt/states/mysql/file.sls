# -*- coding: utf-8 -*-
# vim: ft=sls

mysql_file_policy-rc_create:
  file.managed:
    - name: /usr/sbin/policy-rc.d
    - user: root
    - group: root
    - mode: 555
    - replace: false

mysql_file_policy-rc_modify:
  file.prepend:
    - name: /usr/sbin/policy-rc.d
    - text: '[ -n "$1" ] && [ "$1" = "mysql" ] && [ "$2" = "start" ] && exit 101'
    - require:
      - file: mysql_file_policy-rc_create
