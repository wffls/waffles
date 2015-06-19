`lib/catalog.sh` contains functions related to the Waffles catalog. The catalog is an inventory of all resources that have been used in a role.

At this time, the catalog is built as Waffles is run. This means that you cannot use the catalog to see what resources will be used in the future.

The catalog is used internally to Waffles.

## stdlib.catalog.add

Adds a resource to the catalog. If a resource of the same type and name exist, Waffles will either:

* Error and halt if `WAFFLES_EXIT_ON_DUPLICATE_RESOURCE` is set.
* Print a warning if not.

## stdlib.catalog.exists?

Returns `true` or `false` if a resource is in the catalog.
