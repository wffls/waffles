# Referencing Data from Data Files

[TOC]

## Description

This guide will show how you can reference previously declared data in subsequent data files.

## Steps

* Create an initial data file:

```shell
$ cat > site/data/common.sh <<EOF
data_common_packages=(
  "vim"
  "tmux"
)
EOF
```

* Create a second data file that references data from the first:

```shell
$ cat > site/data/memcached.sh <<EOF
data_common_packages=(
  "htop"
  "${data_common_packages[@]}"
)
EOF
```

* Declare the data files in order in your role:

```shell
waffles.data common
waffles.data memcached
```

## Comments

This is possible because data files are just regular Bash scripts. The variables that have been sourced earlier in the chain are naturally available to files later in the chain. By using regular Bash syntax, you can manipulate the available data in any legal way.
