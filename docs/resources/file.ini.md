# file.ini

## Description

Manages ini files/entries

## Parameters

* state: The state of the resource. Required. Default: present.
* file: The ini file. Required.
* section: The ini file section. Use "__none__" to not use a section. Required.
* option: The ini file setting/option. Required.
* value: The value of the option. Use "__none__" to not set a value. Required.

## Example

```shell
file.ini --file /etc/nova/nova.conf --section DEFAULT --option debug --value True
```

