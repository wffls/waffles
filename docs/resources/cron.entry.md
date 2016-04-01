# cron.entry

## Description

Manages cron entries

## Parameters

* state: The state of the resource. Required. Default: present.
* name: A single-word name for the cron. Required. namevar.
* user: The user to run the cron job as. Default: root.
* cmd: The command to run. Required.
* minute: The minute field of the cron. Default: *.
* hour: The hour field of the cron. Default: *.
* dom: The day of month field for the cron. Default: *.
* month: The month field of the cron. Default: *.
* dow: The day of week field of the cron. Default: *.

## Example

```shell
cron.entry --name foobar --cmd /path/to/some/report --minute "*/5"
```

## TODO

Add support for prefix info such as PATH, MAILTO.

