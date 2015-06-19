# rabbitmq.user

## Description

Manages RabbitMQ users

## Parameters

* state: The state of the resource. Required. Default: present.
* user: The username of the rabbitmq user. Required. namevar.
* password: The password of the rabbitmq user.
* admin: Make the user an admin. Default: false.

## Example

```shell
rabbitmq.user --user root --password password
```

