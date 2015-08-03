# consul.watch

## Description

Manages a consul.watch.

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the watch. Required. namevar.
* type: The type of watch: key, keyprefix, services, nodes, service, checks, event. Required.
* key: A key to monitor when using type "key". Optional.
* prefix: A prefix to monitor when using type "keyprefix". Optional.
* service: A service to monitor when using type "service" or "checks". Optional.
* tag: A service tag to monitor when using type "service". Optional.
* passingonly: Only return instances passing all health checks when using type "service". Optional.
* check_state: A state to filter on when using type "checks". Optional.
* event_name: An event to filter on when using type "event. Optional.
* datacenter: Can be provided to override the agent's default datacenter. Optional.
* token: Can be provided to override the agent's default ACL token. Optional.
* handler: The handler to invoke when the data view updates. Required.
* file: The file to store the watch in. Required. Defaults to /etc/consul/agent/conf.d/watch-name.json

## Example

```shell
consul.watch --name nodes \
             --type nodes \
             --handler "/usr/local/bin/build_hosts_file.sh"
```

