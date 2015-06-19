# rabbitmq.vhost

## Description

Manages RabbitMQ vhosts

## Parameters

* state: The state of the resource. Required. Default: present.
* vhost: The vhostname of the rabbitmq vhost. Required. namevar.

## Example

```shell
rabbitmq.vhost --vhost openstack
```

