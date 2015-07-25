# Install Waffles

## Description

This guide will show how to install Waffles.

## Steps

1. Clone the repository to a directory of your choice:

```shell
$ git clone https://github.com/jtopjian/waffles .waffles
$ cd .waffles
```

2. Create a data file:

```shell
$ cat > site/data/memcached.sh <<EOF
data_memcached_interface="0.0.0.0"
EOF
```

3. Create a profile:

```shell
$ cat > site/profiles/memcached/scripts/server.sh <<EOF
stdlib.title site/profiles/memcached/server
stdlib.apt --package memcached --version latest
stdlib.file_line --name memcached.conf/listen --file /etc/memcached.conf --line "-l $data_memcached_server_listen" --match "^-l"
stdlib.sysvinit --name memcached

if [[ $stdlib_state_change == true ]]; then
  stdlib.mute /etc/init.d/memcached restart
fi
```

4. Create a role:

```shell
$ cat > site/roles/memcached.sh <<EOF
stdlib.data memcached
stdlib.profile memcached/server
```
