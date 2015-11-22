# stdlib.sudo_cmd

## Description

Provides an easy way to give a user sudo access to a single command.

## Parameters

* state: The state of the resource. Required. Default: present.
* user: The user of the sudo privilege. Required. namevar.
* command: The command of the sudo privilege. Required. namevar.
* password: Whether to prompt for a password. Required. Default: false.

## Example

```shell
stdlib.sudo_cmd --user consul --command /usr/local/bin/consul_build_hosts_file.sh
```

