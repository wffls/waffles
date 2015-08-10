# augeas.ssh_authorized_key

## Description

Manages ssh_authorized_keys

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The ssh_authorized_key. Required. namevar.
* key: The ssh key. Required.
* type: The key type. Required.
* key_options: A CSV list of ssh_authorized_key options. Optional
* file: The ssh_authorized_keys file. Required.

## Example

```shell
augeas.ssh_authorized_key --name jdoe --key "AAAAB3NzaC1..." --type ssh-rsa --comment "jdoe@laptop" --file "/root/.ssh/authorized_keys"
```

## Notes

TODO: `options` have not been tested.

