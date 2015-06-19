# mysql.user

## Description

Manages MySQL users

## Parameters

* state: The state of the resource. Required. Default: present.
* user: The username of the mysql user. unique.
* host: The host of the mysql user. Required. unique.
* password: The password of the mysql user.

Unintuitively, user and password are optional because MySQL allows blank usernames and blank passwords.

## Example

```shell
mysql.user --user root --password password
```

