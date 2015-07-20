# stdlib.file_line

## Description

Manages single lines in a file.

## Parameters

* state: The state of the resource. Required. Default: present.
* name: An arbitrary name for the resource. namevar.
* line: The line to manage. Required.
* file: The file that the line belongs to. Required.
* match: A regex to match to. Optional.

## Example

```shell
stdlib.file_line --name "/etc/memcached.conf -l" \
                 --file /etc/memcached.conf \
                 --line "-l 0.0.0.0" --match "^-l"
```

