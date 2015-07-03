# apache.setting

## Description

Manages key/value settings in an Apache config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* key: The name of the setting. Required. namevar.
* value: The value of the setting. Required. namevar.
* path: The path leading up to the key. Optional. Multi. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/apache2/apache2.conf. namevar.

## Example

```shell
apache.setting --path "VirtualHost=*:80" \
               --path "Directory=/" \
               --key Require --value valid-user \
               --file /etc/apache2/sites-enabled/000-default.conf
```

