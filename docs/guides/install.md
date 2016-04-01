# Install Waffles

[TOC]

## Description

This guide will show how to install and use Waffles.

## Steps

* Clone the repository to a directory of your choice and install:

```shell
$ git clone https://github.com/jtopjian/waffles .waffles
$ cd .waffles
$ make install
```

There are two ways to use Waffles: via Wafflescripts or using Roles and Profiles.

### Wafflescript

Create and execute a shell script similar to the following:

```shell
#!/usr/local/bin/wafflescript

apt.pkg --package memcached --version latest
# Install memcached
apt.pkg --package memcached --version latest

# Set the listen option
file.line --file /etc/memcached.conf --line "-l 0.0.0.0" --match "^-l"

# Determine the amount of memory available and use half of that for memcached
memory_bytes=$(terminus System.Memory.Total 2>/dev/null)
memory=$(( $memory_bytes / 1024 / 1024 / 2 ))

# Set the memory available to memcached
file.line --file /etc/memcached.conf --line "-m $memory" --match "^-m"

# Manage the memcached service
service.sysv --name memcached

if [[ $waffles_state_changed == true ]]; then
  exec.mute /etc/init.d/memcached restart
fi
```

### Roles and Profiles

* Create a data file:

```shell
$ mkdir site/data
$ cat > site/data/memcached.sh <<EOF
data_memcached_interface="0.0.0.0"
EOF
```

* Create a profile:

```shell
$ mkdir -p site/profiles/memcached/scripts
$ cat > site/profiles/memcached/scripts/server.sh <<EOF
apt.pkg --package memcached --version latest
file.line --file /etc/memcached.conf --line "-l $data_memcached_server_listen" --match "^-l"
service.sysv --name memcached

if [[ $waffles_state_changed == true ]]; then
  exec.mute /etc/init.d/memcached restart
fi
```

* Create a role:

```shell
$ mkdir site/roles
$ cat > site/roles/memcached.sh <<EOF
waffles.data memcached
waffles.profile memcached/server
```

* Execute Waffles:

```shell
$ bash /etc/waffles.sh -r memcached
```

## More Information

For more information about Data, Profiles, and Roles, see the [usage](/usage) doc.
