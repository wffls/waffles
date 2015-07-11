# rabbitmq.auth_mechanism

## Description

Manages auth_mechanism settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* mechanism: The auth mechanism. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.auth_mechanism --mechanism PLAIN
```

