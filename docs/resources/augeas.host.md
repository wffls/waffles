# augeas.host

## Description

Manages hosts in /etc/hosts

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The host. Required. namevar.
* ip: The IP address of the host. Required.
* aliases: A CSV list of host aliases. Optional
* file: The hosts file. Default: /etc/hosts.

## Example

```shell
augeas.host --name example.com --ip 192.168.1.1 --aliases www,db
```

