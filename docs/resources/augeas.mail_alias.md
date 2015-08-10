# augeas.mail_alias

## Description

Manages aliases in /etc/aliases

## Parameters

* state: The state of the resource. Required. Default: present.
* account: The mail account. Required. namevar.
* destination: The destination for the account. Required.
* alias: Additional aliases for the account. Optional. Multi-value.
* file: The aliases file. Default: /etc/aliases.

## Example

```shell
augeas.mail_alias --account root --destination /dev/null
```

