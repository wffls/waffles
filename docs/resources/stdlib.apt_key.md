# stdlib.apt_key

## Description

Manages apt keys

## Parameters

* state: The state of the resource. Required. Default: present.
* name: An arbitrary name. Required. namevar.
* key: The key to import. Required if no remote_keyfile.
* keyserver: The key server. Required if no remote_keyfile.
* remote_keyfile: A remote key to import. Required if no key or keyserver.

## Example

```shell
stdlib.apt_key --name "foobar" --key 1C4CBDCDCD2EFD2A
```

