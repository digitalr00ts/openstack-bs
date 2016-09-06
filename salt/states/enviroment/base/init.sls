  # -*- coding: utf-8 -*-
  # vim: ft=sls

{##
Name: path/filename.sls
Description: Description of what the state does
Pillars: pillars used in states in this file
Grains: grains used in states in this file
##}

include:
  - packages.software-properties-common
  - packages.python-software-properties
  - packages.resolvconf.purge
  - packages.ppa-mitaka
  # - packages.system-update
  - packages.vim
  - packages.chrony
  - packages.python-openstackclient
