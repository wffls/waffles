`lib/resource.sh` contains functions that coordinate resource execution.

## stdlib.resource.process

This function does several things:

* Creates a catalog entry of the resource.
* Calls `stdlib.resource.read`, which in turn calls `calling_resource.read`.
* Compares the resource state versus the state that the resource has been requested to be in.
* Depending on the results of the above, calls `stdlib.resource.x`, which in turn calls `calling_resource.x`.

This function requires two arguments:

* `$1`: The resource type (`stdlib.apt`)
* `$2`: The resource name (`apache2`)

## stdlib.resource.read

Calls `resource_type.read`. May also perform pre and post actions.

## stdlib.resource.create

Calls `resource_type.create`.

Also flags that a resource has changed and increments the amount of total changes made throughout the Waffles run.

## stdlib.resource.update

Calls `resource_type.update`.

Also flags that a resource has changed and increments the amount of total changes made throughout the Waffles run.

## stdlib.resource.delete

Calls `resource_type.delete`.

Also flags that a resource has changed and increments the amount of total changes made throughout the Waffles run.
