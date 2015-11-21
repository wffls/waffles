# consul.template

## Description

Manages a consul.template.

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the template. Required. namevar.
* source: The source of the template. Optional. Defaults to /etc/consul/template/ctmpl/name.ctmpl
* destination: The destination of the rendered template. Required.
* command: An optional command to run after the template is rendered. Optional.
* file: The file to store the template in. Required. Defaults to /etc/consul/template/conf.d/name.json

## Example

```shell
consul.template --name hosts \
                --destination /etc/hosts
```

