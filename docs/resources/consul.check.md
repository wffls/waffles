# consul.check

## Description

Manages a consul.check.

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the check Required. namevar.
* id: A unique ID for the check. Optional.
* service_id: A service to tie the check to. Optional.
* notes: Notes about the check. Optional.
* token: An ACL token. Optional.
* check: The script or http location for the check. Optional.
* type: The type of check: script, http, or ttl. Required.
* interval: The interval to run the script. Optional.
* ttl: The TTL of the check. Optional.
* file: The file to store the check in. Required. Defaults to /etc/consul/agent/conf.d/check-name.json

## Example

```shell
consul.check --name mysql \
             --check "/usr/local/bin/check_mysql.sh" \
             --type "script" \
             --interval "60s"
```

