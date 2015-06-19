# stdlib.ini

## Description

Manages ini files/entries

## Parameters

* state: The state of the resource. Required. Default: present.
* file: The ini file. Required.
* section: The ini file section. Required.
* option: The ini file setting/option. Required.
* value: The value of the option. Required.

## Example

```shell
stdlib.ini --file /etc/nova/nova.conf --section DEFAULT --option debug --value True
```

