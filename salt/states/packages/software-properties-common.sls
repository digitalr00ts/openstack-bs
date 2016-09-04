  # -*- coding: utf-8 -*-
  # vim: ft=sls

{##
Name: path/filename.sls
Description: Description of what the state does
Pillars: pillars used in states in this file
Grains: grains used in states in this file
##}

install-software-properties-common:
  pkg.installed:
    - names:
      - software-properties-common
    - install_recommends: True
    - refresh: True
    - use: packages.defaults
