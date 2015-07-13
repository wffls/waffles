# rabbitmq.disk_free_limit

## Description

Manages disk_free_limit settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* limit_type: Whether mem_relative or absolute Required.
* value: The value of the limit_type. Required.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.disk_free_limit --limit_type mem_relative --value 1.0
```

