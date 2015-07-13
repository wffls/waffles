# rabbitmq.msg_store_file_size_limit

## Description

Manages msg_store_file_size_limit settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* value: The default value. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.msg_store_file_size_limit --value /
```

