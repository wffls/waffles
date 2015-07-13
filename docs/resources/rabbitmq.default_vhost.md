# rabbitmq.default_vhost

## Description

Manages default_vhost settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* vhost: The default vhost. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.default_vhost --vhost /
```

