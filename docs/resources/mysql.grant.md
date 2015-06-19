# mysql.grant

## Description

Manages MySQL grants

## Parameters

* state: The state of the resource. Required. Default: present.
* user: The user to receive the grant. Required. unique.
* host: The host of the user. Required. unique.
* database: The database to apply the grant on. Required.
* privileges: The privileges to grant. Required.

## Example

```shell
mysql.grant --user nova --host localhost --database nova --privileges "SELECT, UPDATE, DELETE"
```

