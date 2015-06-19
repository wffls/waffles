`lib/options.sh` contains functions related to parsing resource options.

## stdlib.options.set_option

This function creates an option in a resource (perhaps its name will be changed in the future).

```shell
  local -A options
  stdlib.options.set_option state   "present"
  stdlib.options.set_option package "__required__"
  stdlib.options.set_option version
  stdlib.options.parse_options "$@"
```

To successfully create a set of options:

* A local `options` variable must be created. If not, the options will be appended to the last resource declared.
* `stdlib.options.set_option` is used with the first argument being the option name and the second argument being an optional default value.
* If the default value is `__required__`, Waffles will error and halt if the option was not set.

## stdlib.options.parse_options

This function cycles through all options that were given in a declared resource. It will report if any required options were not set.
