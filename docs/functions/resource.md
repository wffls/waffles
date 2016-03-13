# Resource Functions

[TOC]

`lib/functions/resource.sh` contains functions that coordinate resource execution.

## waffles.resource.process

This function does several things:

* Creates a catalog entry of the waffles.resource.
* Calls `waffles.resource.read`, which in turn calls `calling_waffles.resource.read`.
* Compares the resource state versus the state that the resource has been requested to be in.
* Depending on the results of the above, calls `waffles.resource.x`, which in turn calls `calling_waffles.resource.x`.

This function requires two arguments:

* `$1`: The resource type (`apt.pkg`)
* `$2`: The resource name (`apache2`)

## waffles.resource.read

Calls `resource_type.read`. May also perform pre and post actions.

## waffles.resource.create

Calls `resource_type.create`.

Also flags that a resource has changed and increments the amount of total changes made throughout the Waffles run.

## waffles.resource.update

Calls `resource_type.update`.

Also flags that a resource has changed and increments the amount of total changes made throughout the Waffles run.

## waffles.resource.delete

Calls `resource_type.delete`.

Also flags that a resource has changed and increments the amount of total changes made throughout the Waffles run.
