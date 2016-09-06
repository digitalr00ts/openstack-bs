# ``apache`` formula configuration:
apache:

mysql:
  # lookup:
  #   server: mariadb-server-5.5
  server:
    mysqld:
      #bind-address: 0.0.0.0
      default-storage-engine: innodb
      innodb_file_per_table: noarg_present
      max_connections: 4096
      collation-server: utf8_general_ci
      character-set-server: utf8
  #host: localhost
  database:
    - keystone
  user:
    keystone:
      password: 'keystone'
      databases:
        - host: localhost
        - database: keystone
          grants:
            - 'all privileges'
          grant_option: True

keystone:
  server:
    enabled: true
    version: mitaka
    service_token: 'service_token'
    service_tenant: service
    service_password: 'servicepwd'
    admin_tenant: admin
    admin_name: admin
    admin_password: 'adminpwd'
    admin_email: stackmaster@domain.com
    roles:
      - admin
      - Member
      - image_manager
    bind:
      address: 0.0.0.0
      private_address: 127.0.1.1
      private_port: 35357
      public_address: 127.0.1.1
      public_port: 5000
    api_version: 3
    region: RegionOne
    database:
      engine: mysql+pymysql
      host: 'localhost'
      name: 'keystone'
      password: 'keystone'
      user: 'keystone'
    tokens:
      engine: fernet
    #  max_active_keys: 3
    # token_store: cache
    cache:
      engine: memcached
      host: controller
      port: 11211
    # service:
    #   ceilometer_region01:
    #     service: ceilometer
    #     type: metering
    #     region: region01
    #     description: OpenStack Telemetry Service
    #     user:
    #       name: ceilometer
    #       password: password
