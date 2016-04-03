# How to Use Waffles

[TOC]

## Execution Methods

You can run Waffles in two different ways:

* Wafflescripts: a convenient way to create simple shell scripts that take advantage of Waffles's rich library of functions and resources.
* Data, Roles, and Profiles (DRP): enables the design of reusable components that can then be composed into various roles. These roles can then be pushed to remote nodes for easy provisioning.

## Wafflescripts

Creating a Wafflescript is the easist way to get up and running with Waffles. However, Wafflescripts are not as flexible or scalable as Data, Roles, and Profiles. In addition, Wafflescripts can only be run locally at this time.

Wafflescripts look like any other shell script. Simply create a file with the `wafflescript` shebang and then execute one or more Waffles functions and resources as well as any other shell code:

```shell
#!/usr/local/bin/wafflescript

log.info "Hello, World!"
apt.pkg --package memcached --version latest
echo "Goodbye, World!"
```

## Data, Roles, and Profiles (DRP)

### The "site" directory

All of your Data, Roles, and Profiles will go under the "site" directory. By default, this directory is `waffles/site`, but you can change it by setting `WAFFLES_SITE_DIR` in either:

* The environment (environment variable)
* The `waffles/waffles.conf` file

!!! Note
    See the [Environment Variables](/guides/environment-vars) Guide for more information.

### Data

Data files are stored in `site/data`. They're regular Bash scripts and it's only by convention that you store "data", and not programming logic, in these files.

So what is "data"? It's all of the settings that make your site or environment unique:

* IP Addresses
* Usernames, UIDs, GIDs
* Package versions
* Firewall rules

A Data file called `memcached.sh` could look like this:

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

!!! Note
    You can name the variables anything you'd like, though the Waffles naming convention is to start each variable with `data_`.

!!! Warning
    Bash associative arrays _must_ be declared as global variables. This is because all files are sourced inside a Bash function and, for whatever reason, associative arrays are not visible outside of a function (unlike all other Bash variable types).

#### Referencing Data

Once you've created some "data" in a data file, you can refer to it by doing the following:

```shell
waffles.data memcached

echo $data_memcached_listen
```

`waffles.data` is a function that takes a single argument: the name of a data file.

#### Data Structure

The placement of data files is flexible. You can do any of the following:

```shell
waffles.data common       => site/data/common.sh
waffles.data common       => site/data/common/init.sh
waffles.data common/users => site/data/common/users.sh
waffles.data memcached    => site/data/memcached.sh
waffles.data memcached    => site/data/memcached/init.sh
```

#### Hierarchial Data

By declaring multiple data files in your role, you can create a hierarchy of data. For example:

```shell
waffles.data common
waffles.data memcached
```

In the above, common settings that are applicable to _any_ role are stored in `site/data/common.sh`. Only data relevant to the `memcached` service is stored in `site/data/memcached.sh`.

You can even declare the same variable in both data files. The data file declaring it last will overwrite all previous declarations and win.

Finally, you can reference data from a previously declared data file. You can't, however, reference variables in data files _before_ they are declared. To clarify: `site/data/memcached.sh` can reference data from `site/data/common.sh`, but not vice versa.

!!! Note
    See the [Referencing Data from Data](/guides/referencing-data-from-data) and [Overriding Data](/guides/override-data) Guides for more information.

#### Profile Data

Profile-specific data can be stored in `profile_name/data.sh`. This enables data unique to the profile, but generic to the site, to be bundled within the profile and stored in a repository outside of `$WAFFLES_SITE_DIR`.

To use profile data, simply declare it as you would with site data:

```shell
waffles.data memcached
```

When both site and profile data exists, the site data will be referenced _first_. This means that you can create variables in the site data and use them in the profile data. This might seem counter-intuitive, but allows the ability to embed site-specific data into profile-wide data structures:

```shell
declare -Ag data_openstack_keystone_settings=(
  [DEFAULT/admin_token]="$set_this_in_the_site_data.sh"
  [DEFAULT/debug]="true"
  [DEFAULT/verbose]="true"
)
```

### Profiles

Profiles are small snippets of bash scripts stored under `site/profiles`. They are meant to be distinct units of work that accomplish a single task.

For example, you may have a Profile that installs the `memcached` package, a Profile that configures `/etc/memcached.conf`, and a Profile that sets up the `memcached` daemon. Or you may choose to have a single Profile that does all three tasks. Waffles does not enforce any rules to how you design your Profiles.

!!! Warning
    It's possible to call Profiles from other Profiles, but that's not an encouraged practice.

#### Profile Structure

Profiles have a standard structure to them:

```shell
site/profiles/consul/
├── data.sh
├── files
│   └── consul.conf
└── scripts
    ├── install_linux.sh
    └── server.sh
```

Static files go under `files` while scripts go under `scripts`. Profile-specific data can be stored in `data.sh`

!!! Note
    When using the `os.file` resource, you can use the `--source` option to copy files to their destination. The `--source` option is able to reference any file on the system. It's recommended to use `$profile_files/file.conf` when "sourcing" a file.

The `waffles.profile` function is similar to `waffles.data`: it takes a single argument, which is the name of a profile. The following translations are possible:

```shell
waffles.profile common/users    => site/profiles/common/scripts/users.sh
waffles.profile common/packages => site/profiles/common/scripts/packages.sh
waffles.profile memcached       => site/profiles/memcached/scripts/init.sh
waffles.profile memcached/utils => site/profiles/memcached/scripts/utils.sh
```

#### Git Profiles

Waffles supports the ability to store profiles in a git repository. To use this feature, include the following in the role:

```shell
git.profile https://github.com/jtopjian/waffles-profile-openstack --branch dev
```

This will clone https://github.com/jtopjian/waffles-profile-openstack as `$WAFFLES_SITE_DIR/profiles/openstack` with the `dev` branch checked out.

Once the above is declared, profile scripts can be referenced like normal:

```shell
waffles.profile openstack/keystone
```

Profile names are based on the repository name. Waffles will split the repository name by dashes (`-`) and use the last portion of the name.

`git.profile` has the following syntax:

```
git.profile https://github.com/jtopjian/waffles-profile-openstack
git.profile https://github.com/jtopjian/waffles-profile-openstack --branch dev
git.profile https://github.com/jtopjian/waffles-profile-openstack --tag 0.5.1
git.profile https://github.com/jtopjian/waffles-profile-openstack --commit 023a83
```

If you are pushing to a remote node and the remote node does not have access to the git repository, you can check out the repository on the Waffles "server" and then push it to the remote node by using `--push`:

```
git.profile https://github.com/jtopjian/waffles-profile-openstack --branch dev --push true
```

#### The Hosts Profile

Waffles supports an optional special profile called `host_files`, located at `site/profiles/host_files`. The purpose of this profile is to provide an area where files and scripts specific to individual hosts can be stored. This is beneficial because, normally, the entire profile is copied to each node that uses the profile. If you are storing files such as SSL certs in a profile, all SSL certs would be then copied to all hosts that share the profile.

The `host_files` profile has the following structure:

```shell
site/profiles/host_files/
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
waffles.profile host_files
```
!!! Warning
    This means that `host_files` is a reserved name.

### Roles

A "role" is a name that identifies a unique configuration set. Examples of roles could be:

  * `memcached`
  * `memcached_apt`
  * `memcached_yum`
  * `memcached_yum_lxc`
  * `memcached_and_redis`

Role names are up to you -- just make sure _you_ understand that applying the `memcached_yum_lxc` role to an Ubuntu-based KVM virtual machine probably won't work.

Roles are defined in `site/roles`.

!!! Note
    A role is really just another Bash script. It's possible to use Waffles to organize a collection of deployment scripts simply by placing them under the `site/roles` directory.

To use roles most effectively, think of them as glue between _data_ and _profiles_:

A very simple role could look like this:

```shell
# Reads data from site/data/common.sh
waffles.data common

# Reads data from site/data/memcached.sh
waffles.data memcached

# Reads site/profiles/common/scripts/users.sh
waffles.profile common/users

# Reads site/profiles/common/scripts/packages.sh
waffles.profile common/packages

# Reads site/profiles/memcached/scripts/init.sh
waffles.profile memcached
```

### Applying Roles

Waffles supports two ways of applying roles:

#### Local Execution

You can run `waffles.sh` directly on a node and Waffles will apply the role to that node. For example:

```shell
$ waffles.sh -r memcached
```

This is most useful when you copy the entire contents of the `waffles` directory to a node, log into the node, and manually run `waffles.sh`.

#### Remote Execution (push)

It's possible to run Waffles on a remote node by pushing the configuration via rsync and SSH. To do this, use the `-s <server>` flag. For example:

```shell
$ waffles.sh -s www.example.com -r web
```

The benefit of this method is that only the data and profiles referenced in the role will be copied to the remote node. So if you have several other profiles, such as for MySQL or RabbitMQ, those profiles will not be copied to a node acting as a `memcached` node.

!!! Note
    At this time, both the Waffles server and destination node must have rsync and installed.
