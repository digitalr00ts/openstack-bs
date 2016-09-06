include:
  - packages.system-update

install-ubuntu-cloud-keyring:
  pkg.latest:
    - name: ubuntu-cloud-keyring
    - install_recommends: True
    - refresh: True
    - use: packages.defaults

add-mitaka-ppa:
  pkgrepo.managed:
    - name: deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/mitaka main
    - file: /etc/apt/sources.list.d/cloudarchive-mitaka.list
    - refresh_db: True
    - require:
      - install-ubuntu-cloud-keyring
      - install-software-properties-common
      - install-python-software-properties
    - watch_in:
      - pkg: system-update

add-mitaka-ppa-src:
  pkgrepo.managed:
    - name: deb-src http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/mitaka main
    - file: /etc/apt/sources.list.d/cloudarchive-mitaka.list
    - disabled: True
