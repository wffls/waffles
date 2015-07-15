# keepalived.vrrp_script

## Description

Manages vrrp_script section in keepalived.conf

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the VRRP instance. Required. namevar.
* script: The script to define. Required.
* interval: The interval to run the script. Optional.
* weight: The points for priority. Optional.
* fall: Number of failures for KO. Optional.
* raise: Number of successes for OK. Optional.
* file: The file to store the settings in. Required. Defaults to /etc/keepalived/keepalived.conf.

## Example

```shell
keepalived.vrrp_script --name check_apache2 \
                       --script "killall -0 apache2"
```

