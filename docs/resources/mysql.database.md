# mysql.database

## Description

Manages MySQL databases

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the database. Required. namevar.
* charset: The character set of the database.
* collate: The collation of the database.

## Example

```shell
mysql.database --name root --password password
```

