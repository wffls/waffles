# Changelog

## 0.30.3 Unreleased

* resource: Fixed a typo in apt_ppa.sh (@gbraekmans) [GH-173]
* core: Have resources check for dependent commands. Error early if missing. [GH-176]
* core: Added a new function ini_file in functions/ini_file.sh (@gbraekmans) [GH-180]
* resource: `file.ini` has been rewritten to take advantage of new ini functions (@gbraekmans) [GH-180]
* resource: New `dnf.pkg` resource (@gbraekmans) [GH-175]
* resource: New `dnf.copr` resource (@gbraekmans) [GH-175]
* resource: New `dnf.repo` resource (@gbraekmans) [GH-175]
* resource: Re-added `augeas.generic` resource [GH-189]
* resource: New `ruby.gem` resource [GH-192]
* resource: Added overwrite option to `os.symlink` [GH-193]

## 0.30.2 July 2, 2016

* Fixed typo in `file.ini` resource.
* Added `WAFFLES_NO_HELP` environment variable which will prevent `--help` test from printing. This is due to incompatibilities with `wafflescript` at the moment.

## 0.30.1 June 19, 2016

* Renamed `sudo.cmd` to `sudoers.cmd`

## 0.30.0 June 14, 2016

### Major Update

This commit is a major refactor of Waffles.

This repository can be considered Waffles "core". It contains the core functionality of Waffles as a suite of Bash scripts. These scripts can be sourced into any Bash script and then used to manage resources. The `init.sh` script can also be source on the command-line and the user can interactively execute the Waffles-based resources.

Functionality that has been removed from this repository (data, profiles, stacks) will appear in separate repositories.

The previous incarnation of Waffles exists under the `0.22` branch. This branch will be maintained for a short time and will receive patches where appropriate.

### Fixes

* `os.symlink` heavily rewritten so options make more sense.

## 0.22.0 June 4, 2016

### Major Update

The concept of `stdlib` was removed from Waffles. See [this commit](https://github.com/jtopjian/waffles/commit/fbe51753e446755018007a69fa10f1ed7950e670) for details. You can use the `contrib/legacy_migration.sh` script to convert your work. For now, all old `stdlib.*` resource calls should be caught and a warning will be printed. This will be removed in a future release.

### Features

* New Feature: `wafflescript`: Run a Waffles script by using `#!/usr/local/bin/wafflescript` as the interpreter.
* New Feature: Waffleseeds: Compile a Waffles Role into a self-contained executable.
* New Feature: Stacks: Profiles can combine several scripts into a stack located in `profile_name/stacks/stack_name.sh`.
* Removed Feature: `stdlib.enable_*` functions have been removed. *Possible breakage*.
* New Feature: Default remote dir is now `~/.waffles`.
* New Feature: Timestamps in logs.
* New Functions: `waffles.pushd` and `waffles.popd`

## 0.21.0 March 5, 2016

* New Resource: `stdlib.symlink`.
* New Feature: Basic template support.
* New Feature: `$profile_name`, `$profile_path`, `$profile_file` variables.
* New Feature: All output goes to STDOUT.
* New Feature: `stdlib.file_line` no longer requires a `--name` parameter. *Possible breakage*.
* New Feature: `stdlib.debconf` no longer requires a `--name` parameter. *Possible breakage*.
* New Feature: Toggle color output.
* Fixed: zero-prefixed permissions (750 -> 0750)
* Fixed: several `stdlib.ini` fixes.
* Fixed: Account for multiple grants when checking with `mysql.grant`.
* Fixed: Hostname and socket conflicts in `mysql.mycnf`.

## 0.20.0 January 1, 2016

* New Resource: `stdlib.sudo_exec`.
* New Feature: `stdlib.title` is no longer required in profiles. *Possible breakage*.
* New Feature: SSH retry and backoff.
* New Feature: Profile data.
* New Feature: git profiles.
* Enhanced: Moved stdlib-related things to an explicit `stdlib` directory.

## 0.19.0 - November 5, 2015

* New Resource: `python.virtualenv`
* New Resource: `python.pip`
* Updated: Documentation
* Updated: `mysql.grant` can use `ALL` as an alias for `ALL PRIVILEGES`.
* Fixed: `stdlib.apt_ppa` state. Thanks @primeroz.
* Fixed: Determining Upstart-based statuses.

## 0.18.0 - September 28, 2015

* New Feature: Host Profile support. Can manage files for an individual host.
* Enhanced: Added admonition plugin to docs.
* Enhanced: Lots of documentation updates.
* Enhanced: `stdlib.ini`: Allows settings without a `[section]`.
* Enhanced: Run `rsync` in quiet mode unless Waffles is run in debug mode.
* Enhanced: Waffles remote: SSH key and better SITE directory handling.
* Enhanced: `stdlib.capture_error` returns exit codes.
* Enhanced: Better support for required options.
* Updated: `consul.get_nodes` only returns node names and addresses. Not ports.
* Updated: Several Augeas-based resources were refactored to use the new `augeas.generic` resource.
* Removed: `consul.build_hosts_file`.
* Fixed: git repo read.
* Fixed: Ensure the resource state is reset before each read.
* Fixed: Typo in sourcing RabbitMQ resource.
* Fixed: `stdlib.split` issue with repeating characters.
* Fixed: `stdlib.array_*` functions were all refactored and tests have been created.

## 0.17.0 - August 8, 2015

* New resource: `stdlib.sudo_cmd`.
* New resource: `consul.template`.
* New resource: `augeas.generic`.
* New function: `stdlib.hash_keys`.
* Enhanced `stdlib.ini`: Allows for single-word entries.
* Fixed `stdlib.directory`.
* Fixed `stdlib.debconf`.
* Fixed `stdlib.file`.
* Fixed `stdlib.ini`.
* Fixed GRANT queries in `mysql.grant`.
* Doc updates (@reduxionist).

## 0.16.0 - July 25, 2015

* New resource: Initial Consul resources.
* Major resource refactor.
* Conditional quoting style changes.
* Test Kitchen additions and fixes.
* Reset subtitle on title change.

## 0.15.0 - July 20, 2015

* New function: `stdlib.array_contains`.
* Updated resource: `augeas.json_array`.
* Fixed `version` option in `stdlib.apt`.
* New resources: keepalived.

## 0.14.0 - July 12, 2015

* New resource: More RabbitMQ resources.

## 0.13.0 - July 3, 2015

* Ensure consistent quoting in conditionals.
* Added syntax check to tests.
* Fixed typo in sourcing RabbitMQ resource.

## 0.12.0 - July 2, 2015

* New resource: apache.

## 0.11.0 - July 2, 2015

* Renamed `stdlib.join` to `stdlib.array_join`.

## 0.10.0 - July 1, 2015

* New resource: nginx.

## 0.9.1 - June 28, 2015

* Cleaning up catalog entries.

## 0.9.0 - June 28, 2015

* Added multi-value option support.

## 0.8.0 - June 28, 2015

* Added several array functions.

## 0.7.0 - June 28, 2015

* New function: `stdlib.join`.

## 0.6.0 - June 28, 2015

* `stdlib.split` now accepts multi-character delimiters.

## 0.5.1 - June 27, 2015

* Fixing tests.

## 0.5.0 - June 27, 2015

* Renamed `set_option` to `create_option`.

## 0.4.0 - June 27, 2015

* Added `system` flag to `stdlib.useradd`.
* Fixing tests.

## 0.3.0 - June 19, 2015

* New resource: git.

## 0.2.2 - June 19, 2015

* mkdocs updates.

## 0.2.1 - June 19, 2015

* Documentation Updates.

## 0.2.0 - June 16, 2015

* Added `stdlib.debug_mute`.

## 0.1.2 - June 11, 2015

* Added two recipes: LXC and Terraform.
* Fixed documentation index.

## 0.1.1 - June 11, 2015

Remote Deployment (push) Updates.

Enhancements were made to the push-based remote deployment:

* Able to handle explicit IPv6 addresses
* Able to specify a destination directory
* Able to specify if sudo should be used remotely

## 0.1.0 - June 9, 2015

Waffles initial release.

Waffles is a simple configuration management and deployment system written in Bash. I started this project both to see if such a tool was possible as well as to create a more simple deployment system for my own experiments.

The initial release of Waffles contains a variety of resources and documentation. It's able to configure local nodes as well as remote nodes via `rsync`.
