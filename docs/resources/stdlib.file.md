# stdlib.file

## Description

Manages files

## Parameters

* state: The state of the resource. Required. Default: present.
* owner: The owner of the directory. Default: root.
* group: The group of the directory. Default: root.
* mode: The perms/mode of the directory. Default: 750.
* name: The destination file. Required. namevar.
* content: STDIN content for the file. Optional.
* source: Source directory to copy. Optional.

## Example

```shell
stdlib.file --file /etc/foobar --content "Hello, World!"
```

