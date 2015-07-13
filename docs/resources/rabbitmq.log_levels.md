# rabbitmq.log_levels

## Description

Manages log_levels settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* category: The log category. Required. namevar.
* level: The log level. Optional. Defaults to info
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.log_levels --category connection --level debug
rabbitmq.log_levels --category channel --level error
```

