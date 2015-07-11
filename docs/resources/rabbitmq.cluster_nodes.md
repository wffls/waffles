# rabbitmq.cluster_nodes

## Description

Manages cluster_nodes settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* node: A node. Required. Multi-var.
* cluster_type: The cluster type. Optional. Defaults to disc.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.cluster_nodes --node rabbit@my.host.com --node rabbit@my2.host.com --cluster_type ram
```

