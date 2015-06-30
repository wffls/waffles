# nginx.events

## Description

Manages events key/value settings in nginx.conf

## Parameters

* state: The state of the resource. Required. Default: present.
* key: The key. Required.
* value: A value for the key. Required.
* file: The file to store the settings in. Optional. Defaults to /etc/nginx/nginx.conf.

## Example

```shell
nginx.events --key worker_connections --value 768
```

