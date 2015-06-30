# nginx.map

## Description

Manages entries in an nginx.map block

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the map definition. Required.
* source: The source of the map definition. Required.
* variable: The variable of the map definition. Required.
* key: The key. Required.
* value: A value for the key. Required.
* file: The file to store the settings in. Optional. Defaults to /etc/nginx/conf.d/map_name.

## Example

```shell
nginx.map --name my_map --source '$http_host' --variable '$name' --key default --value 0
nginx.map --name my_map --source '$http_host' --variable '$name' --key example.com --value 1
```

