# rabbitmq.hipe_compile

## Description

Manages hipe_compile settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* value: The default value. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.hipe_compile --value /
```

