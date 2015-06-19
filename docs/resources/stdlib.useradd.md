# stdlib.useradd

## Description

Manages users

## Parameters

* state: The state of the resource. Required. Default: present.
* user: The user Required. namevar.
* uid: The uid of the user Optional.
* gid: The gid of the user Optional.
* createhome: Whether to create the homedir. Default: false.
* sudo: Whether to give sudo ability: Default: false.
* shell: The shell of the user. Default /usr/sbin/nologin.
* comment: The comment field. Optional.
* homedir: The homedir of the user. Optional.
* passwd: The password hash. Optional.
* groups: Supplemental groups of the user. Optional.

## Example

```shell
stdlib.useradd --user jdoe --uid 999 --createhome true --homedir /home/jdoe
               --shell /bin/bash --comment "John Doe"
```

