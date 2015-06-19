# stdlib.apt_ppa

## Description

Manages PPA repositories

## Parameters

* state: The state of the resource. Required. Default: present.
* ppa: The PPA. Required. namevar.
* refresh: run apt-get update if the PPA was modified. Default: true.

## Example

```shell
stdlib.apt_ppa --ppa ppa:chris-lea/redis-server
```

