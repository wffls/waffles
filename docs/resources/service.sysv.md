# service.sysv

## Description

Manages sysv-init services

## Parameters

* state: The state of the service. Required. Default: running.
* name: The name of the service. Required. namevar.

## Example

```shell
service.sysv --name memcached
```

