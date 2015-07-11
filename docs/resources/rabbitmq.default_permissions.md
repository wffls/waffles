# rabbitmq.default_permissions

## Description

Manages default_permissions settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* conf: The conf permission. Required.
* read: The read permission. Required.
* write: The write permission. Required.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.default_permissions --conf ".*" --read ".*" --write ".*"
```

