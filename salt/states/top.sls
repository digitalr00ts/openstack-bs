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
    - enviroment.base

server:
  'controller*':
    - enviroment.controller
#
# computes:
#   'compute*':
#     - enviroment.compute
