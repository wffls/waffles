# stdlib.iptables_rule

## Description

Manages iptables rules

## Parameters

* state: The state of the resource. Required. Default: present.
* name: An arbitrary name for the rule. Required. namevar.
* priority: An arbitrary number to give the rule priority. Required. Default 100.
* table: The table to add the rule to.. Required. Default: filter.
* chain: The chain to add the rule to. Required. Default: INPUT.
* rule: The rule. Required.
* action: The action to take on the rule. Required. Default: ACCEPT.

## Example

```shell
stdlib.iptables_rule --priority 100 --name "allow all from 192.168.1.0/24" --rule "-m tcp -s 192.168.1.0/24" --action ACCEPT
```

