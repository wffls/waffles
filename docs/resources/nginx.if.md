# nginx.if

## Description

Manages key/value settings in an nginx server if block

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The conditional of the if block. Required. namevar.
* server_name: The name of the nginx_server resource. Required.
* key: The key. Required.
* value: A value for the key. Required.
* file: The file to add the variable to. Optional. Defaults to /etc/nginx/sites-enabled/server_name.

## Example

```shell
nginx.if --name '$request_method !~ ^(GET|HEAD|POST)$' --server_name example.com --key return --value 444
```

