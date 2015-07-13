# rabbitmq.auth_backend

## Description

Manages auth_backend settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* backend: The auth backend. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.auth_backend --backend PLAIN
```

