# apt.pkg

## Description

Manage packages via apt.

## Parameters

* state: The state of the resource. Required. Default: present.
* package: The name of the package. Required. namevar.
* version: The version of the package. Leave empty for first version found. Set to "latest" to always update.

## Example

```shell
apt.pkg --package tmux --version latest
```

