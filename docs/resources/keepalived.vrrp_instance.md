# keepalived.vrrp_instance

## Description

Manages vrrp_instance section in keepalived.conf

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the VRRP instance. Required. namevar.
* vrrp_state: The state of the VRRP instance. Required.
* interface: The interface to monitor. Required.
* virtual_router_id: The virtual router ID. Required.
* priority: The priority. Required.
* advert_int: The advert interval. Optional.
* auth_type: The authentication type. Optional.
* auth_pass: The authentication password. Optional.
* virtual_ipaddress: A virtual IP address. Optional. Multi-var.
* smtp_alert: Send an email during transition. Optional. Defaults to false.
* unicast_src_ip: Source IP for unicast packets. Optional.
* unicast_peer: A peer in a unicast group. Optional. Multi-var.
* native_ipv6: Force IPv6. Optional. Defaults to false.
* notify_master: The notify_master script. Optional.
* notify_backup: The notify_backup script. Optional.
* notify_fault: The notify_fault script. Optional.
* notify: The notify script. Optional.
* debug: Enable debugging. Optional. Defaults to false.
* file: The file to store the settings in. Required. Defaults to /etc/keepalived/keepalived.conf.

## Example

```shell
keepalived.vrrp_instance --name VI_1 \
                         --vrrp_state MASTER \
                         --interface eth0 \
                         --virtual_router_id 42 \
                         --priority 100 \
                         --virtual_ipaddress 192.168.1.10
```

