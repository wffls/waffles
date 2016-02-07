# stdlib.file_line

## Description

Manages single lines in a file.

## Parameters

* state: The state of the resource. Required. Default: present.
* file: The file that the line belongs to. Required.
* line: The line to manage. Required.
* match: A regex to match to. Optional.

## Example

```shell
stdlib.file_line --file /etc/memcached.conf \
                 --line "-l 0.0.0.0" --match "^-l"
```

