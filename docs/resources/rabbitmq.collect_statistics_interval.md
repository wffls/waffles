# rabbitmq.collect_statistics_interval

## Description

Manages collect_statistics_interval settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* interval: The default interval. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.collect_statistics_interval --interval /
```

