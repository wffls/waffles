# rabbitmq.default_user_tags

## Description

Manages default_user_tags settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* tag: The auth tag. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.default_user_tags --tag PLAIN
```

