# -*- coding: utf-8 -*-
# vim: ft=sls

{##
Name: path/filename.sls
Description: Description of what the state does
Pillars: pillars used in states in this file
Grains: grains used in states in this file
##}

base:
  '*':
    - .mysql

servers:
  'controller*':
    - server.single
#
# computes:
#   'compute*':
#     - enviroment.compute
