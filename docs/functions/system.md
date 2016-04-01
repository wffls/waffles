# System Functions

`lib/functions/system.sh` contains functions that are considered core to Waffles.

[TOC]

## array.contains

Reports true if element exists in an array.

```shell
x=(foo bar baz)
if array.contains "x" "foo" ; then
  echo "Exists"
fi
```

## array.join

Joins an array into a string.

```shell
x=(foo bar baz)
array.join x ,
=> foo,bar,baz
```

## array.length

Returns the length of an array.

```shell
x=(a b c)
array.length x
=> 3
```

## array.pop

Removes and the last element from array $1 and optionally stores it in $2

```shell
x=(a b c)
array.pop x y
echo $y
=> c
```

## array.push

Adds an element to the end of an array.

```shell
x=()
array.push x foo
```

## array.shift

Removes and returns the first element from array $1 and optionally stores it in $2

```shell
x=(a b c)
array.shift x y
echo $y
=> a
```

## array.unshift

Adds an element to the beginning of the array.

```shell
x=(b c)
array.unshift x a

```

## waffles.build_ini_file

Builds an ini file from a given hash.

```shell
waffles.build_ini_file data_openstack_keystone_settings /etc/keystone/keystone.conf
```

## exec.capture_error

Takes a command as input, prints the command, and detects if anything was written to `stderr`. If there was, the error is printed to `stderr` again, and if `WAFFLES_EXIT_ON_ERROR` is set, Waffles halts.

```shell
exec.capture_error apt-get update
```

## waffles.command_exists

A simple wrapper around `which`.

```shell
if [[ waffles.command_exists apt-get ]]; then
  log.info "We're on a Debian-based system."
fi
```

## waffles.data

The same as `waffles.profile` but the shell scripts can be placed differently:

```shell
waffles.data common => data/common.sh
waffles.data common => data/common/init.sh
waffles.data common/users => data/common/users.sh
waffles.data memcached => data/memcached.sh
waffles.data memcached => data/memcached/init.sh
```

## log.debug

Prints a log message at `debug` level.

```shell
log.debug "Foobar"
```

## waffles.debug

Determines if Waffles is being run in `debug` mode.

```shell
if waffles.debug ; then
  log.debug "We're in debug mode."
fi
```

## exec.debug_mute

Like `exec.mute` but messages only appear in `debug` mode.

```shell
exec.debug_mute apt-get update
```

## waffles.dir

A simple function that returns the current directory of the script currently being run.

## log.error

Prints an error message to `stderr`.

```shell
log.error "Foobar"
```

## exec.run

A simple function that takes a command as input, prints the command, and then executes it.

```shell
exec.run apt-get update
```

## git.profile

git.profile will check a profile out from a git repository.

git.profile repositories must be named:

```
waffles-profile-$profile_name
```

git.profiles must follow the following syntax:

```
git.profile https://github.com/jtopjian/waffles-profile-openstack
git.profile https://github.com/jtopjian/waffles-profile-openstack --branch dev
git.profile https://github.com/jtopjian/waffles-profile-openstack --tag 0.5.1
git.profile https://github.com/jtopjian/waffles-profile-openstack --commit 023a83
```

If you are deploying to remote nodes and those nodes do not have access to the git server:

```
git.profile https://github.com/jtopjian/waffles-profile-openstack --branch dev --push true
```

## hash.keys

Returns the keys of a hash / associative array.

```shell
declare -A foo=(
  [a]=1
  [b]=2
  [c]=3
)

hash.keys "foo"
=> a b c

x=($(hash.keys "foo"))
echo "${x[1]}"
=> b
```

## waffles.include

A more intelligent `source`. It checks if the file being sourced / included exists, and if not, prints a warning and moves on.

## log.info

Prints a log message at `info` level.

```shell
log.info "Foobar"
```

## exec.mute

Prints the command being run, but suppresses the command output.

```shell
exec.mute apt-get update
```

## waffles.noop

Determines if Waffles is being run in `noop` mode.

```shell
if waffles.noop ; then
  log.info "We're in noop mode."
fi
```

## waffles.profile

Takes a profile as input and determines the shell script attached to the profile.

If Waffles is being run locally, then `waffles.include` is run on the script. If Waffles is being run in push-based mode, then the profile is marked to be copied to the remote node.

```shell
waffles.profile common/users => profiles/common/scripts/users.sh
waffles.profile common/packages => profiles/common/scripts/packages.sh
waffles.profile memcached => profiles/memcached/scripts/init.sh
waffles.profile memcached/utils => profiles/memcached/scripts/utils.sh
```

## string.split

Splits a string into an array. Stores the result in `__split`. The delimiter can be multi-character.

```shell
string.split "foo/bar", "/"
log.info $__split[1] # bar
```

## waffles.subtitle

Sets a subtitle context. This is usually used internally by resources. An internal counter to determine if the resource was changed:

```shell
$ cat profiles/common/scripts/package.sh
# waffles.title = `common/package`
apt.pkg --package sl # waffles.subtitle = apt.pkg

if [[ $waffles_resource_changed == true ]]; then
  log.info "The state of package sl changed"
fi

apt.pkg --package cowsay # waffles.subtitle = apt.pkg

if [[ $waffles_resource_changed == true ]]; then
  log.info "The state of package cowsay changed"
fi
```

## exec.sudo

Runs a command as another user via sudo:

```shell
exec.sudo username tar xzvf foobar.tar.gz
```

## waffles.title

Sets a title context. This is usually used internally. Whenever a new profile script is run, Waffles will set the title automatically to `profile_name/script_name`.

Internal counters are reset whenever `waffles.title` is used. This is useful for determining if any changes were made to a resource or the profile as a whole:

```shell
$ cat profiles/common/scripts/package.sh
# waffles.title = `common/package`
apt.pkg --package sl # waffles.subtitle = apt.pkg
apt.pkg --package cowsay # new waffles.subtitle = apt.pkg

if [[ $waffles_state_changed == true ]]; then
  log.info "One of the above packages were updated."
fi
```

## string.trim

Trims the whitespace on both sides of a string.

```shell
trimmed=$(string.trim "   foobar   "
```

## log.warn

Prints a warning message.

```shell
log.warn "Foobar"
```

# System Variables

`lib/system.sh` contains variables that can be used throughout your scripts.

## profile_files

Returns the path to the profile files directory.

```shell
echo $profile_files
/etc/waffles/site/profiles/memcached/files

os.file --name /tmp/foo.txt --source "$profile_files/foo.txt"
```

## profile_name

Returns the name of the profile currently being run.

```shell
echo $profile_name
memcached
```

## profile_path

Returns the path of the profle currently being run.

```shell
echo $profile_path
/etc/waffles/site/profiles/memcached
```

## role

Returns the role currently being run.

``shell
echo $role
memcached_server
```
