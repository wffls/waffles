# consul.service

## Description

Manages a consul service.

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the service. Required. namevar.
* id: A unique ID for the service. Optional.
* tag: Tags to describe the service. Optional. Multi-var.
* address: The address of the service. Optional.
* port: The port that the service runs on. Optional.
* token: An ACL token. Optional.
* check: The script or location for the check. Optional. Multi-var.
* check_type: The type of check. Optional. Multi-var.
* check_interval: The interval to run the script. Optional. Multi-var.
* check_ttl: The TTL of the check. Optional. Multi-var.
* file: The file to store the service in. Required. Defaults to /etc/consul/agent/conf.d/service-name.json
* file_owner: The owner of the service file. Optional. Defaults to root.
* file_group: The group of the service file. Optional. Defaults to root.
* file_mode: The mode of the service file. Optional. Defaults to 0640

## Example

```shell
consul.service --name mysql \
               --port 3306 \
               --check_type "script" \
               --check "/usr/local/bin/check_mysql.sh" \
               --check_interval "60s"
```

