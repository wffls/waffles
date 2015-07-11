# rabbitmq.vm_memory_high_watermark

## Description

Manages vm_memory_high_watermark settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* value: The default value. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.vm_memory_high_watermark --value /
```

