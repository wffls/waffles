# How to Use Waffles

## Roles

In Waffles, a "role" is a name that identifies a unique configuration set. Examples of roles could be:

  * `memcached`
  * `memcached_apt`
  * `memcached_yum`
  * `memcached_yum_lxc`
  * `memcached_and_redis`

Role names are totally up to you -- just make sure _you_ understand that applying the `memcached_yum_lxc` role to an Ubuntu-based KVM virtual machine probably won't work.

For the sake of simplicity, we'll call our role `memcached`.

Roles are defined in `site/roles`. `site` is a special directory that will hold the configuration for your _site_ or environment. You most likely wouldn't be able to transfer `site` to a new environment and have it run without some level of modification.

A role is really just a Bash script, and if you'd prefer to just use Waffles to organize a collection of deployment scripts, go for it.

To use roles most effectively, think of them as glue between _data_ and _profiles_:

* Data is settings that make your site unique: user IDs, config file settings, package versions, etc.
* Profiles are small snippets of scripts that make up a unique service configuration.

A very simple role could look like this:

```shell
# Reads data from site/data/common.sh
stdlib.data common

# Reads data from site/data/memcached.sh
stdlib.data memcached

# Reads site/profiles/common/scripts/users.sh
stdlib.profile common/users

# Reads site/profiles/common/scripts/packages.sh
stdlib.profile common/packages

# Reads site/profiles/memcached/scripts/init.sh
stdlib.profile memcached
```

## Data

Scripts stored in `site/data` are, again, just regular Bash scripts. It's only by convention that you store data, and not programming logic, in these files.

So what is "data"? It's all of the settings that make your site or environment unique:

* IP Addresses
* Usernames, UIDs, GIDs
* Package versions
* Firewall rules

Data files look like this:

```shell
data_memcached_listen="0.0.0.0"

declare -Ag data_user_info
data_user_info=(
  [jdoe|uid]=999
  [jdoe|gid]=999
  [jdoe|comment]="John doe"
  [jdoe|homedir]="/home/jdoe"
  [jdoe|shell]="/bin/bash"
  [jdoe|create_home]=true
)
```

You can name the variables anything you like, though the Waffles naming convention is to start each variable with `data_`.

Note: Bash associative arrays _must_ be declared as global variables. This is because all files are sourced inside a Bash function and, for whatever reason, associative arrays are not visible outside of a function (unlike all other Bash variable types).

### Hierarchial Data

By declaring multiple data files in your role, you can create a hierarchy of data. For example:

```shell
stdlib.data common
stdlib.data memcached
```

In the above, common settings that are applicable to _any_ role are stored in `site/data/common.sh`. Only data relevant to the `memcached` service is stored in `site/data/memcached.sh`.

You can even declare the same variable in both data files. The data file declaring it last will overwrite all previous declarations and win.

Finally, you can reference data from a previously declared data file. You can't, however, reference variables in data files _before_ they are declared. To clarify: `site/data/memcached.sh` can reference data from `site/data/common.sh`, but not vice versa.

### Data Structure

The placement of data files is flexible. You can do any of the following:

```shell
stdlib.data common => data/common.sh
stdlib.data common => data/common/init.sh
stdlib.data common/users => data/common/users.sh
stdlib.data memcached => data/memcached.sh
stdlib.data memcached => data/memcached/init.sh
```

## Profiles

Profiles are small snippets of bash scripts that are called from Roles. These profiles are run in a top-down fashion. Waffles does not support any other method of order.

It's possible to call Profiles from other Profiles, but that's not an encouraged practice.

Profiles are meant to be shared among multiple roles. This easily makes sense for profiles like `common/users`, but when would you re-use `memcached`? How about between a development and production environment? The same profile could be used in both roles and it would be the job of the data to provide the information that makes each environment different:

__Development Memcached__

```shell
stdlib.data common
stdlib.data development/memcached

stdlib.profiles common/users
stdlib.profiles common/packages
stdlib.profiles memcached
```

__Production Memcached__

```shell
stdlib.data common
stdlib.data production/memcached

stdlib.profiles common/users
stdlib.profiles common/packages
stdlib.profiles memcached
```

Waffles does not enforce this pattern -- you are free to design your roles however you like.

### Profile Structure

Unlike Data and Roles, Profiles have a standard structure to them:

```shell
consul/
├── files
│   └── consul.conf
└── scripts
    ├── install_linux.sh
    └── server.sh
```

Static files go under `files` while scripts go under `scripts`.

When using the `stdlib.file` resource, you can use the `--source` option to copy files to their destination. The `--source` option is restricted to only being able to copy from the `files` directory.

When declaring profiles in roles, the following translations happen:

```shell
stdlib.profiles common/users => profiles/common/scripts/users.sh
stdlib.profiles common/packages => profiles/common/scripts/packages.sh
stdlib.profiles memcached => profiles/memcached/scripts/init.sh
stdlib.profiles memcached/utils => profiles/memcached/scripts/utils.sh
```

### The Hosts Profile

Waffles supports an optional special profile called `host_files`, located at `site/profiles/host_files`. The purpose of this profile is to provide a designated area where files and scripts specific to individual hosts can be stored. This is beneficial because, normally, the entire profile is copied to each node that uses the profile. If you are storing files such as SSL certs in a profile, all SSL certs would be then copied to all hosts that share use the profile. This is probably not intended behavior.

The `host_files` profile has the following structure:

```shell
host_files/
├── mysql-01
│   └── files
│       ├── mysql-01.crt
│       └── mysql-01.key
├── mysql-02
│   └── files
│       ├── mysql-02.crt
│       └── mysql-02.key
└── rabbit-01
    ├── files
    │   ├── rabbit-01.crt
    │   └── rabbit-01.key
    └── scripts
        └── custom.sh
```

Each subdirectory of the `host_files` profile is an individual host or node, named after the hostname (not FQDN). The directory of these subdirectories is like a normal profile with the usual `files` and `scripts` subdirectories.

Inside your role, you can enable this special profile by doing:

```shell
stdlib.profile host_files
```

This means that a profile with the name `host_files` is a reserved name.

## Applying Roles

Waffles supports two ways of applying roles:

### Local Execution

You can run `waffles.sh` directly on a node and Waffles will apply the role to that node. This is most useful when you copy the entire contents of the `waffles` directory to a node.

### Remote Execution (push)

It's possible to run Waffles on a remote node by pushing the configuration via rsync and SSH. To do this, use the `-s <server>` flag. For example:

```shell
$ waffles.sh -s www.example.com -r web
```

Note: at this time, both the Waffles server and destination node must have rsync installed.

### Remote Execution (pull)

Waffles does not support pull-based deployment yet.
