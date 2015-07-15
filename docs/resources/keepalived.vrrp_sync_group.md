# keepalived.vrrp_sync_group

## Description

Manages vrrp_sync_group section in keepalived.conf

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the VRRP instance. Required. namevar.
* group: The name of a VRRP instance. Required. Multi-var.
* file: The file to store the settings in. Required. Defaults to /etc/keepalived/keepalived.conf.

## Example

```shell
keepalived.vrrp_sync_group --name VSG_1 \
                           --group VI_1 \
                           --group VI_2 \
```

