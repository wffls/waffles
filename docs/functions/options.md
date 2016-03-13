# Options Options

[TOC]

`lib/functions/options.sh` contains functions related to parsing resource options.

## waffles.options.create_option

This function creates an option in a waffles.resource.

```shell
local -A options
waffles.options.create_option state   "present"
waffles.options.create_option package "__required__"
waffles.options.create_option version
waffles.options.parse_options "$@"
```

To successfully create a set of options:

* A local `options` variable must be created. If not, the options will be appended to the last resource declared.
* `waffles.options.create_option` is used with the first argument being the option name and the second argument being an optional default value.
* If the default value is `__required__`, Waffles will error and halt if the option was not set.

## waffles.options.create_mv_option

This function creates a multi-value option. These types of options can be specified multiple times. In order to use, you must declare
an array of the same name as the option. For example, the `augeas.mail_alias` resource looks like this:

```shell
local -A options
local -a destination
waffles.options.create_option    state       "present"
waffles.options.create_option    account     "__required__"
waffles.options.create_mv_option destination "__required__"
waffles.options.create_option    file        "/etc/aliases"
waffles.options.parse_options    "$@"
```

Now when declaring an alias, you can do:

```shell
augeas.mail_alias --root --destination jdoe --destination jsmith --destination foobar
```

## waffles.options.parse_options

This function cycles through all options that were given in a declared waffles.resource. It will report if any required options were not set.
