# nginx.global

## Description

Manages global key/value settings in nginx.conf

## Parameters

* state: The state of the resource. Required. Default: present.
* key: The key. Required.
* value: A value for the key. Required.
* file: The file to store the settings in. Optional. Defaults to /etc/nginx/nginx.conf.

## Example

```shell
nginx.global --key user --value www-data
nginx.global --key worker_processes --value 4
```

