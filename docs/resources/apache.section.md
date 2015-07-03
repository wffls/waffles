# apache.section

## Description

Manages an apache section.

## Parameters

* state: The state of the resource. Required. Default: present.
* type: The type of the section Required. namevar.
* name: The name of the section Required. namevar.
* path: The path leading up to the type. Optional. Multi. namevar.
* file: The file to store the settings in. Optional. Defaults to /etc/apache2/apache2.conf. namevar.

## Example

```shell
apache.section --type Directory --name /
apache.section --path "VirtualHost=*:80" --type Directory --name /
```

