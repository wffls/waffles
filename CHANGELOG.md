# Changelog

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
