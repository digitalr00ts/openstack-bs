#apt-update:
#  cmd.run:
#    - name: apt-get update

{##
Name: path/filename.sls
Description: Description of what the state does
Pillars: pillars used in states in this file
Grains: grains used in states in this file
##}

system-update:
  pkg.uptodate:
    - refresh: True
    - kwargs: 'force_yes'
