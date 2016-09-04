  # -*- coding: utf-8 -*-
  # vim: ft=sls

{##
Name: path/filename.sls
Description: Description of what the state does
Pillars: pillars used in states in this file
Grains: grains used in states in this file
##}

install-chrony:
  pkg.installed:
    - name: chrony
    - install_recommends: True
    - use: packages.defaults
