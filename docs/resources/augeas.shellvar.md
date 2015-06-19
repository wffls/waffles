# augeas.shellvar

## Description

Manages simple kv settings in a file.

## Parameters

* state: The state of the resource. Required. Default: present.
* key: The key. Required. namevar.
* value: A value for the key. Required.
* file: The file to add the variable to. Required. namevar.

## Example

```shell
augeas.shellvar --key foo --value bar --file /root/vars
```

