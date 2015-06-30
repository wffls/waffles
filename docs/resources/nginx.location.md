# nginx.location

## Description

Manages key/value settings in an nginx server location block

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the location block. Required. namevar.
* server_name: The name of the nginx_server resource. Required.
* key: The key. Required.
* value: A value for the key. Required.
* file: The file to add the variable to. Optional. Defaults to /etc/nginx/sites-enabled/server_name.

## Example

```shell
nginx.location --name '~ \.php$' --server_name example.com --key try_files --value '$uri $uri/ @dw'
```

