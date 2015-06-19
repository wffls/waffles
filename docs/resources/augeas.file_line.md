# augeas.file_line

## Description

Manages single lines in a file

## Parameters

* state: The state of the resource. Required. Default: present.
* name: An arbitrary name for the line. Required. namevar.
* line: The line to manage in the file. Required.
* file: The file to add the line. Required. namevar.

## Example

```shell
augeas.file_line --file /root/foo.txt --line "Hello, World!"
```

