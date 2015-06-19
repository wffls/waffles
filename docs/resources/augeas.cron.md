# augeas.cron

## Description

Manages a cron entry in /etc/cron.d/

## Parameters

* state: The state of the resource. Required. Default: present.
* name: An arbitrary name for the cron Required. namevar.
* user: The user to run the cron under. Default: root.
* minute: The minute to run the cron. Default: *.
* hour: The hour to run the cron. Default: *.
* dom: The day of month to run the cron. Default: *.
* month: The month to run the cron. Default *.
* dow: The day of the week to run the cron. Default *.
* cmd: The command to run. Required.

## Example

```shell
augeas.cron --name metrics --minute "*/5" --cmd /usr/local/bin/collect_metrics.sh
```

