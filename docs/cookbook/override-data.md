# Override Data

## Description

This recipe will show how to easily override data in two different data files

## Steps

1. Create the initial data file:

```shell
$ cat site/data/common.sh <<EOF
data_memcached_uid="999"
EOF
```

2. Create the second data file:

```shell
$ cat site/data/memcached.sh <<EOF
data_memcached_uid="700"
EOF
```

3. Add both data files to your role. The file called last will take precedence:

```shell
site.data common
site.data memcached
```

## Comments

This is useful for when you want to keep data that can be used across multiple roles in a single file, but some roles need individual pieces of data overridden. A common case for this is when you are introducing a configuration management system into an existing environment and something like user UIDs have not been made standard.
