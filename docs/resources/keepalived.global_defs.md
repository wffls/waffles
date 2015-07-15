# keepalived.global_defs

## Description

Manages global_defs section in keepalived.conf

## Parameters

* state: The state of the resource. Required. Default: present.
* notification_email: Email address to send notifications. Optional. Multi-var.
* notification_email_from: The From address on email notifications. Optional.
* smtp_server: The smtp server to send notifications. Optional.
* smtp_connect_timeout: Connect timeout for sending notifications. Optional.
* router_id: The router ID. Optional.
* vrrp_mcast_group4: VRRP multicast group for IPv4. Optional.
* vrrp_mcast_group6: VRRP multicast group for IPv6. Optional.
* file: The file to store the settings in. Optional. Defaults to /etc/keepalived/keepalived.conf.

## Example

```shell
keepalived.global_defs --notification_email root@localhost \
                       --notification_email jdoe@example.com \
                       --smtp_server smtp.example.com \
                       --router_id 42
```

