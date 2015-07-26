# Waffles Resources

This document will cover how resources are used in Waffles.

## Location

All resources are stored in the `$WAFFLES_DIR/lib` directory:

* The Standard Library of resources is located in `$WAFFLES_DIR/lib/resources`.
* Apache-based resources are located in `$WAFFLES_DIR/lib/apache`.
* Augeas-based resources are located in `$WAFFLES_DIR/lib/augeas`.
* Consul-based resources are located in `$WAFFLES_DIR/lib/consul`.
* Keepalived-based resources are located in `$WAFFLES_DIR/lib/keepalived`.
* MySQL-based resources are located in `$WAFFLES_DIR/lib/mysql`.
* Nginx-based resources are located in `$WAFFLES_DIR/lib/nginx`.
* RabbitMQ-based resources are located in `$WAFFLES_DIR/lib/rabbitmq`.

## Enabling Non-Standard Resources

By default, only the Standard Library is enabled in Waffles. To enable the other resources, use the following functions:

* Apache: `stdlib.enable_apache`
* Augeas: `stdlib.enable_augeas`
* Consul: `stdlib.enable_consul`
* Keepalived: `stdlib.enable_keepalived`
* MySQL: `stdlib.enable_mysql`
* Nginx: `stdlib.enable_nginx`
* RabbitMQ: `stdlib.enable_rabbitmq`

## Anatomy of a Resource

### Header

Each resource has a detailed comment header. This header describes what the resource does, what parameters it takes, how to use it, and any comments. The comment header is very important as this is where the resource documentation is generated from.

### function resource.name

The next part of a resource is the first "function". This first function is named after the resource name. So any time you use a resource, you're actually just calling a Bash function.

The first thing done inside this function is to call a "subtitle" with `stdlib.subtitle`. Subtitles serve two purposes:

1. They set the name to be printed when running Waffles.
2. They reset an internal flag for changes made in the resource. This flag is called `stdlib_resource_change`. See the "State Changes" section for more details.

Next, an `options` variable is declared. It is important that this variable is declared in each resource. If not, then the resource will share variables with the last called resource. After the `options` variable is declared, any parameters for the resource are declared. Finally, variables are checked via `stdlib.options.parse_options`. All logic related to `options` can be found in `$WAFFLES_DIR/lib/options.sh`.

After options, any local variables are defined.

Next, any optional custom logic is defined. This usually includes local variables just for the resource or ensuring that correctly formatted parameters were given.

Next, `stdlib.resource.process` is called.

### function stdlib.resource.process

This is a centralized function that was introduced to help reduce repeated code in all resources. It does the following:

* A catalog entry is made.
* `stdlib.resource.read` is called, which in turn calls `calling_resource.read`.
* A comparison is made of the resource state versus the state that the resource should be in.
* Depending on the results of the above, `stdlib.resource.x` is called, which in turn calls `calling_resource.x`.

Each of the `stdlib.resource.x` functions do a few other things like determine if a resource change was made and how many changes were made throughout the entire run. In the future, these functions may also generate summary reports of the run.

### function resource.name.x

The rest of the resource is made up of four standard functions:

* function.name.read
* function.name.create
* function.name.update
* function.name.delete

Some resources contain extra functions, but they always tie back into those standard four. Sometimes `function.name.update` just calls `delete` and `create`.

If you create a resource that conforms to those four functions, it'll work just fine in Waffles.

### function resource.name.read

The `read` function determines the current state of the resource. For example, `stdlib.apt.read` determines if the package is installed, and if so, what version is installed.

### function resource.name.create

The `create` function does whatever is required to create the the resource. For example, `stdlib.apt.create` installs a package via `apt` and `stdlib.file_line.create` adds a line to a given file either by `echo` or `sed`.

It's important to try to stick with a core philosophy of Waffles: use standard nix utilities for the creation of resources.

### function resource.name.update

If the work required to update a resource is different than creating a resource, use the `update` function. However, if it's easier to simply delete the resource and recreate it, then do that instead of an update function. Just don't use that method as an excuse.

### function resource.name.delete

This function deletes the resource. For example, `stdlib.apt.delete` will actually remove the package.

## State Changes

After you call a resource, you can check the status of the `stdlib_resource_change` flag. If it is true, then a change happened when you called the resource. For example:

```shell
stdlib.apt --package sl --version latest

if [[ $stdlib_resource_change == "true" ]]; then
  stdlib.info "Package sl was installed or upgraded."
fi
```

Similar to `stdlib_resource_change` is `stdlib_state_change`. `stdlib_state_change` works in the exact same way, but it is reset when a call to `stdlib.title` is made. You usually use `stdlib.title` at the beginning of Profiles.

## Examples

Use the Standard Library and Augeas resources as examples of how resources are built.
