# stdlib.git

## Description

Manage a git repository

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name (path) of the git repo destination. Required.
* source: The URI of the source git repo. Required.
* branch: The branch to checkout. Optional. Default: master.
* tag: The tag to checkout. Optional.
* commit: the commit to checkout. Optional.
* owner: The owner of the repo. Default: root.
* group: The group owner of the repo. Default: root.

## Example

```shell
git --state latest --name /root/.dotfiles --source https://github.com/jtopjian/dotfiles
```

## Notes

If state is set to "latest", Waffles will do a `git pull` if it's able to.

The order of checkout preferences is:

* commit
* tag
* branch

