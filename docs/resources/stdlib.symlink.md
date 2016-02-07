# stdlib.symlink

## Description

Manages symlinks

## Parameters

* state: The state of the resource. Required. Default: present.
* destination: The destination link. Required. namevar.
* source: Source file. Required.

## Example

```shell
stdlib.symlink --source /usr/local/bin/foo --destination /usr/bin/foo
```

