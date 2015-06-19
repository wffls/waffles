# rabbitmq.policy

## Description

Manages RabbitMQ policies

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the policy. Required. namevar.
* vhost: The vhost to apply the policy to. Default: /.
* queues: The queues to apply the policy to. Default: all.
* policy: The policy. Required.

## Example

```shell
rabbitmq.policy --name openstack-ha --vhost openstack --policy '{"ha-mode":"all"}'
```

