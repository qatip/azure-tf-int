#cloud-config
package_update: true
runcmd:
  - echo "Hello, ${name}!" > /var/log/startup.log
