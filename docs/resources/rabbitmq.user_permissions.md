# rabbitmq.user_permissions

## Description

Manages RabbitMQ user permissions

## Parameters

* state: The state of the resource. Required. Default: present.
* user: The username@vhost of the rabbitmq user. Required. namevar.
* conf: The conf portion of the set_permissions command. Default: '.*'
* write: The write portion of the set_permissions command. Default: '.*'
* read: The read portion of the set_permissions command. Default: '.*'

## Example

```shell
rabbitmq.user_permission --user_permission root --password password
```

