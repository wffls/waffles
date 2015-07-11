# rabbitmq.tcp_listeners

## Description

Manages tcp_listeners settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* address: The address to listen on. Required. namevar.
* port: The port to listen on. Optional. Defaults to 5672.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.tcp_listeners --address 127.0.0.1 --port 5672
rabbitmq.tcp_listeners --address ::1 --port 5672
```

