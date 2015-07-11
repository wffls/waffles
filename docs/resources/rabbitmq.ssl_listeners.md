# rabbitmq.ssl_listeners

## Description

Manages ssl_listeners settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* port: The port to listen on. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.ssl_listeners --port 5671
```

