# stdlib.debconf

## Description

Manages debconf entries

## Parameters

* state: The state of the resource. Required. Default: present.
* package: The package to configure. Required.
* question: The debconf question. Required.
* vtype: The vtype of the debconf setting. Required.
* value: The answer/setting. Required.

## Example

```shell
stdlib.debconf --package mysql-server --question mysql-server/root_password
               --vtype password --value mypassword
```

