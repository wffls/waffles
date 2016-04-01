# os.file

## Description

Manages files

## Parameters

* state: The state of the resource. Required. Default: present.
* owner: The owner of the file Default: root.
* group: The group of the file Default: root.
* mode: The perms/mode of the file Default: 0640.
* name: The destination file. Required. namevar.
* content: STDIN content for the file. Optional.
* source: Source file to copy. Optional.

## Example

```shell
os.file --name /etc/foobar --content "Hello, World!"
```

