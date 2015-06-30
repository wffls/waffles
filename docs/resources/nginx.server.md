# nginx.server

## Description

Manages key/value settings in an nginx server block

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the server. Required. namevar.
* server_name: The domain of the server. Optional. Defaults to name.
* key: The key. Required.
* value: A value for the key. Required.
* file: The file to store the settings in. Optional. Defaults to /etc/nginx/sites-enabled/name.

## Example

```shell
nginx.server --name example.com --key root --value /var/www/html
nginx.server --name example.com --key listen --value 80
nginx.server --name example.com --key index --value index.php
```

