# Environment Variable Support

[TOC]

## Description

This guide will show how to alter Waffles's behavior by setting different environment variables.

## WAFFLES_NOOP

no-op stands for "no operation". Rather than actually executing commands, it will print what _would have_ happened if Waffles was run in normal mode.

### Steps

1. Run Waffles with `WAFFLES_NOOP` set:

```shell
$ WAFFLES_NOOP=1 waffles.sh memcached
```

### Comments

You can also use the `-n` flag when running Waffles.

## WAFFLES_DEBUG

This will print extra information about each action. If Waffles is not working correctly, try running in "debug" mode and see if you can spot the error.

The output from "debug" mode is also the best way to report bugs.

### Steps

1. Run Waffles with `WAFFLES_DEBUG` set:

```shell
$ WAFFLES_DEBUG=1 waffles.sh memcached
```

### Comments

You can also use the `-d` flag when running Waffles.

## TEST

When TEST is set, Waffles will exit 1 if any changes were made. This is useful to verify the previous run was successful because no changes should need to be made upon the second execution.

### Steps

1. Run Waffles with `WAFFLES_TEST` set:

```shell
$ WAFFLES_TEST=1 waffles.sh memcached
```

### Comments

You can also use the `-t` flag when running Waffles.
