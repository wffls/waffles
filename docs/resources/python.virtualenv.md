# python.virtualenv

## Description

Manage a python virtualenv

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the virtualenv package. Required.
* venv_dir: The path / parent directory to the virtual environment. Required. Default: /usr/local"
* requirements: The path to a requirements.txt file. Optional.
* systempkgs: Copy system site-packages into the virtualenv. Required. Default: false.
* distribute: Distribute method. Required. Default: distribute
* index: An alternative pypi index file. Optional.
* owner: The owner of the virtualenv. Required. Default: root.
* group: The group of the virtualenv. Required. Default: root.
* mode: The directory mode of the venv. Required. Default: 755.
* environment: Additional environment variables. Optional.
* pip_args: Extra pip args. Optional.
## Example

```shell
python.virtualenv --name foo
```

## Notes

This resource is heavily based on puppet-python

