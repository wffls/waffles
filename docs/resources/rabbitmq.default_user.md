# rabbitmq.default_user

## Description

Manages default_user settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* user: The default user. Required. namevar.
* pass: The default password. Required. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.default_user --user guest --pass guest
```

