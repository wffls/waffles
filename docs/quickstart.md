# Waffles

## Introduction

Waffles is a lightweight configuration management system written in bash, simiar to other tools such as Puppet, Chef, or Ansible.

## Quickstart

If you just want to get up and running with Waffles, follow these steps:

1. Clone the waffles repository:

```shell
$ git clone https://github.com/jtopjian/waffles .waffles
```

2. Review the `waffles.conf` file and make any appropriate changes.

3. Create `/root/.waffles/site/roles/memcached.sh` with the following contents:

```shell
stdlib.data memcached
stdlib.profile memcached/server
```

4. Create `site/data/memcached.sh` with the following contents:

```shell
data_memcached_server_listen="0.0.0.0"
```

4. Create `site/profiles/memcached/scripts/server.sh` with the following contents:

```shell
stdlib.title profiles/memcached

# Install memcached
stdlib.apt --package memcached --version latest

# Set the listen option
stdlib.file_line --name memcached.conf/listen --file /etc/memcached.conf --line "-l $data_memcached_server_listen" --match "^-l"

# Manage the memcached service
stdlib.sysvinit --name memcached

# Restart memcached if anything changed
if [[ $stdlib_state_change == true ]]; then
  /etc/init.d/memcached restart
fi
```

5. Install `memcached` on the current node you're on by running:

```shell
$ waffles.sh -r memcached
```

The end result will be a simple `memcached` server.

If you'd prefer to provision a remote node with `memcached`, do the following:

```shell
$ waffles.sh -s memcached.example.com -r memcached
```

This assumes you have SSH and rsync access to `memcached.example.com`.
