# stdlib.directory

## Description

Manages directories

## Parameters

* state: The state of the resource. Required. Default: present.
* owner: The owner of the directory. Default: root.
* group: The group of the directory. Default: root.
* mode: The perms/mode of the directory. Default: 750.
* name: The destination directory. Required. namevar.
* source: Optional source directory to copy.
* recurse: Whether to apply all settings recursively. Optional.
* parent: Whether to make the parent directories. Optional.

## Example

```shell
stdlib.directory --source $WAFFLES_SITE_DIR/profiles/foo/files/mydir --name /var/lib/mydir
```

