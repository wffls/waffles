# os.directory

## Description

Manages directories

## Parameters

* state: The state of the resource. Required. Default: present.
* owner: The owner of the directory. Default: root.
* group: The group of the directory. Default: root.
* mode: The perms/mode of the directory. Default: 0750.
* name: The destination directory. Required. namevar.
* source: Optional source directory to copy.
* recurse: Whether to apply all settings recursively. Optional.
* parent: Whether to make the parent directories. Optional.

## Example

```shell
os.directory --source "$profile_files/mydir" --name /var/lib/mydir
```

