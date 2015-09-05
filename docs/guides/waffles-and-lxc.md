# Using Waffles with LXC

[TOC]

## Description

This guide will describe how to configure LXC containers with Waffles.

## Steps

### Installing LXC

First, set up an LXC server. I've written a blog post [here](http://terrarum.net/blog/building-an-lxc-server-1404.html) that may be used as a reference.

### Creating a Base Container

I find it very useful to have a standard container that's used as the basis for all other containers. If anything, it makes the creation of new containers almost instant since cloning a container is much quicker than creating an entirely new container.

To create a base container, just create a standard container and turn it off with `lxc-stop`.

### Waffles LXC Script

I've been using the following script for the past few months and find it works very well. Comments and improvements are definitely welcome, though.

```shell
#!/bin/bash

if [ -z $1 ]; then
  echo "Role required."
  exit 1
fi

lxc-ls | grep -q waffles_$1
if [ $? == 0 ]; then
  echo "Shutting down and destroying waffles_$1"
  lxc-stop -n waffles_$1
  lxc-destroy -n waffles_$1
fi

echo "Cloning LXC container waffles_base to waffles_$1"
lxc-clone -o waffles_base -n waffles_$1 -s

echo "Copying root key to container"
mkdir /var/lib/lxc/waffles_$1/rootfs/root/.ssh
cat /root/.ssh/id_rsa.pub > /var/lib/lxc/waffles_$1/rootfs/root/.ssh/authorized_keys

echo "Starting waffles_$1 and waiting until it has an IP"
lxc-start -d -n waffles_$1

running=false
while [ "$running" == false ]; do
  lxc-info -i -n waffles_$1 | grep -q 10
  if [ $? == 0 ]; then
    ip=$(lxc-info -i -n waffles_$1 | awk '{print $2}')
    running=true
  else
    echo "waffles_$1 not up yet. Sleeping..."
    sleep 2
  fi
done

grep -q waffles_$1 /etc/hosts
if [ $? == 0 ]; then
  sed -i -e "/waffles_$1/d" /etc/hosts
fi
echo "$ip waffles_$1" >> /etc/hosts

pkill -HUP dnsmasq

echo "Running waffles"
lxc-attach -n waffles_$1 -- apt-get update
lxc-attach -n waffles_$1 -- apt-get install -y rsync
cd /root/.waffles && bash waffles.sh -s waffles_$1 -r $1
```

This script assumes the following:

* You have a base container called `waffles_base`.
* You have Waffles installed under `/root/.waffles`.

To use this script, run it like so:

```shell
$ waffles_lxc.sh memcached
```

The script will then clone `waffles_base` as `waffles_memcached` and create an `/etc/hosts` entry for it so all other containers can reference it by name.

If you'd prefer not to have all containers prefixed with `waffles_`, just edit the script.

## Conclusion

This guide detailed one way of using Waffles with LXC by using a simple Bash script that automates the creation of a container and applies a role to it using Waffles.
