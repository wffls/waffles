# nginx.http

## Description

Manages http key/value settings in nginx.conf

## Parameters

* state: The state of the resource. Required. Default: present.
* key: The key. Required.
* value: A value for the key. Required.
* file: The file to store the settings in. Optional. Defaults to /etc/nginx/nginx.conf.

## Example

```shell
nginx.http --key index --value "index.html index.htm index.php"
log_format='main "$remote_addr - $remote_user [$time_local] $status \"$request\" $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\""'
nginx.http --key log_format --value "$log_format"
nginx.http --key access_log --value "/var/log/nginx/access.log main"
```

