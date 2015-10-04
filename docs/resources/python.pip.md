# python.pip

## Description

Manage a pip python package

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the pip package. Required.
* version: The version of the pip package. Optional.
* virtualenv: The virtual environment to put the package in. Required. Default: system.
* url: A URL to install the package from. Optional.
* owner: The owner of the virtualenv. Required. Default: root.
* group: The group of the virtualenv. Required. Default: root.
* index: Base URL of the python package index. Optional.
* editable: If the package is installed as an editable resource. Required. Default: false.
* environment: Additional environment variables. Optional.
* install_args: Additional arguments to use when installing. Optional.
* uninstall-args: Additional arguments to use when uninstalling. Optional.

## Example

```shell
python.pip --name minilanguage
python.pip --name minilanguage --version 0.3.0
python.pip --name minilanguage --version latest
```

## Notes

This resource is heavily based on puppet-python

