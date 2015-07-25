# augeas.ini

## Description

Manages ini file entries

## Parameters

* state: The state of the resource. Required. Default: present.
* section: The section in the ini file. Required. namevar.
* option: The option in the ini file. Required. namevar.
* value: The value of the option. Required.
* file: The file to add the variable to. Required. namevar.

## Example

```shell
augeas.ini --section DEFAULT --option foo --value bar --file /root/vars
```

