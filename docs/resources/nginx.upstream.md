# nginx.upstream

## Description

Manages entries in an nginx upstream block

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the upstream definition. Required. namevar.
* key: The key. Required.
* value: A value for the key. Required.
* options: Extra options for the value. Optional.
* file: The file to store the settings in. Optional. Defaults to /etc/nginx/conf.d/upstream_name.

## Example

```shell
nginx.upstream --name example_com --key server --value server1.example.com --options "weight=5"
nginx.upstream --name example_com --key server --value server2.example.com
```

