# Install Waffles

[TOC]

## Description

This guide will show how to install and use Waffles.

## Steps

* Clone the repository to a directory of your choice:

```shell
$ git clone https://github.com/jtopjian/waffles .waffles
$ cd .waffles
```

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
stdlib.title memcached/server
stdlib.apt --package memcached --version latest
stdlib.file_line --name memcached.conf/listen --file /etc/memcached.conf --line "-l $data_memcached_server_listen" --match "^-l"
stdlib.sysvinit --name memcached

if [[ $stdlib_state_change == true ]]; then
  stdlib.mute /etc/init.d/memcached restart
fi
```

* Create a role:

```shell
$ mkdir site/roles
$ cat > site/roles/memcached.sh <<EOF
stdlib.data memcached
stdlib.profile memcached/server
```

## More Information

For more information about Data, Profiles, and Roles, see the [usage](/usage) doc.
