# augeas.aptconf

## Description

Manages apt.conf settings

## Parameters

* state: The state of the resource. Required. Default: present.
* setting: The setting Required. namevar.
* value: A value for the setting Required.
* file: The file to add the variable to. Required. namevar.

## Example

```shell
augeas.aptconf --setting APT::Periodic::Update-Package-Lists --value 1 --file /etc/apt/apt.conf.d/20auto-upgrades
augeas.aptconf --setting APT::Periodic::Unattended-Upgrade --value 1 --file /etc/apt/apt.conf.d/20auto-upgrades
```

