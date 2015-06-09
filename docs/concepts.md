# Waffles from Scratch

To illustrate Waffles's design, I'll walk through the creation of a Bash script that can successfully run multiple times on a single server and only make changes to the server when required.

## Let's Create a Simple memcached Server in Bash

`memcached` is a very simple service. It's a single daemon with a simple configuration file installed from a single package.

Let's say we want to create a `memcached` server on a Linux container or virtual machine. Rather than running the commands manually, we'll create a Bash script to do the work. This will serve two purposes:

1. Documentation
2. Repeatable process

### The First Draft

The initial Bash script would look something like:

```shell
#!/bin/bash

apt-get install -y memcached
```

### The Second Draft

This works, and doing `ps aux` shows that `memcached` is indeed running. But then we notice that `memcached` is only listening on `localhost`:

```shell
$ netstat nap | grep 11211
```

Since this `memcached` service will be used by other services on the network, we need to change `memcached`'s interface binding to `0.0.0.0`. The following should work:

```shell
$ sed -i -e '/^-l 127.0.0.1$/c -l 0.0.0.0' /etc/memcached.conf
$ /etc/init.d/memcached restart
```

And once that's tested on the command line, we add it to our script:

```shell
#!/bin/bash

apt-get install -y memcached
sed -i -e '/^-l 127.0.0.1$/c -l 0.0.0.0' /etc/memcached.conf
/etc/init.d/memcached restart
```

Astute readers will see an issue. In order for us to test this script, we need to run it again. However, the script is going to report that `memcached` is already installed and an unnecessary restart of `memcached` will take place.

There are two ways to resolve this issue:

The first is by starting over from scratch and running the script on a new server. There's a lot of merit to this method. For example, you can be sure that the exact steps work in sequence on new servers. However, the entire process could take a long time for some situations. Also, what if this `memcached` service was in production? Either you'd have to take the `memcached` service down temporarily while the new service builds or you'd have to find some way of seamlessly adding in the new service while removing the old. While there's benefit to this (which is similar to the current popularity of "microservices"), it may not always be a possible solution.

The second way is to alter the script so that changes are only made if required. If a change does not need to be made, nothing happens.

Let's say it's not possible for us to rebuild from scratch. Therefore, we'll opt for the second option.

### The Third Draft

In order to run our Bash script against a running service without causing (too much of) a disruption, we must ensure that each step is executed only if it needs to be. This means that before any command has run, we must check to see what the current state of the system is, compare it to the change we want to make, and only make the change if the system state does not match.

By doing this, our Bash script becomes a "state declaration" that describes how the `memcached` service should be configured when the script is done running. This is known as [Idempotence](http://en.wikipedia.org/wiki/Idempotence) in Configuration Management.

So let's make our basic Bash script more idempotent:

```shell
dpkg -s memcached &>/dev/null
if [ $? == 1 ]; then
  echo "Installing memcached"
  apt-get install -y memcached
fi

grep -q '^-l 127.0.0.1' /etc/memcached.conf
if [ $? == 0 ]; then
  echo "Updating memcached.conf and restarting it."
  sed -i -e '/^-l 127.0.0.1$/c -l 0.0.0.0' /etc/memcached.conf
  /etc/init.d/memcached restart
fi
```

With this in place, we can now execute this script multiple times on the same server, virtual machine, or container, and if a step has already been done it will not happen again.

### The Fourth Draft

Having to do a bunch of `grep`s and other checks can become very tedious. Waffles tries to resolve this by including a Standard Library of common tasks. Using the Waffles Standard Library, the above script can be re-written as:

```shell
#!/bin/bash

source ./waffles.conf
source ./lib/init.sh

stdlib.apt --package memcached
stdlib.file_line --name memcached.conf/listen --file /etc/memcached.conf --line "-l 0.0.0.0" --match "^-l"
stdlib.sysvinit --name memcached

if [ "$stdlib_state_change" == true ]; then
  /etc/init.d/memcached restart
fi
```

There's nothing magical about these commands. They're a collection of standard Bash functions that sweep all of the messy `grep`s under the carpet. You can see the full collection of Standard Library functions in the `lib/` directory.

### The Fifth Draft

The core `memcached` service is up and running, but there's still a few more tasks that need to be done. For example, maybe we want to create some users:

```shell
stdlib.groupadd --group jdoe --gid 999
stdlib.useradd --user jdoe --uid 999 --gid 999 --comment "John" --shell /bin/bash --homedir /home/jdoe --createhome true
```

`stdlib.useradd` is another Waffles Standard Library function that enables an easy way to create and manage a user on a server.

Looking at the above command, there are a lot of settings that are hard-coded. If we end up creating a `redis` server that also needs the `jdoe` user, we could just copy that line verbatim, but what about a scenario where the `uid` must be changed to `500`? Then we'd need to change every occurrence of `999` to `500`. In large environments, there's a chance some changes would be missed.

To resolve this issue, Waffles allows settings such as this (known as _data_) to be stored in data files.

A simple way of using data is to just throw all settings into a file called `site/data/common.sh`.

Let's add a user:

```shell
data_users=(
  jdoe
)

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

Waffles data variables can be named anything, but if you want to follow the project standards, have the variables start with `data_`.

With all of this in place, the fifth draft now looks like:

```shell
#!/bin/bash

source ./waffles.conf
source ./lib/init.sh

stdlib.data common

for user in "${data_users[@]}"; do

  homedir="${data_user_info[${user}|homedir]}"
  uid="${data_user_info[${user}|uid]}"
  gid="${data_user_info[${user}|gid]}"
  comment="${data_user_info[${user}|comment]}"
  shell="${data_user_info[${user}|shell]}"
  create_home="${data_user_info[${user}|create_home]}"

  stdlib.groupadd --group "$user" --gid "$gid"
  stdlib.useradd --state present --user "$user" --uid "$uid" --gid "$gid" --comment "$comment" --homedir "$homedir" --shell "$shell" --createhome "$createhome"

done

stdlib.apt --package memcached
stdlib.file_line --name memcached.conf/listen --file /etc/memcached.conf --line "-l 0.0.0.0" --match "^-l"
stdlib.sysvinit --name memcached

if [ "$stdlib_state_change" == true ]; then
  /etc/init.d/memcached restart
fi
```

### The Sixth Draft

The block of user data can be re-used in other scripts. It'd be best if we just moved it out into its own separate script. By repeating this process, we can create a library of re-usable components. Final scripts then become "compositions" of the collection of scripts.

Create the directory structure `site/profiles/common/scripts` and add the following to `site/profiles/common/scripts/users.sh`

```shell
for user in "${data_users[@]}"; do

  homedir="${data_user_info[${user}|homedir]}"
  uid="${data_user_info[${user}|uid]}"
  gid="${data_user_info[${user}|gid]}"
  comment="${data_user_info[${user}|comment]}"
  shell="${data_user_info[${user}|shell]}"
  create_home="${data_user_info[${user}|create_home]}"

  stdlib.groupadd --group "$user" --gid "$gid"
  stdlib.useradd --state present --user "$user" --uid "$uid" --gid "$gid" --comment "$comment" --homedir "$homedir" --shell "$shell" --createhome "$createhome"

done
```

And so the sixth draft now looks like:

```shell
#!/bin/bash

source ./waffles.conf
source ./lib/init.sh

stdlib.data common
stdlib.profile common/users

stdlib.apt --package memcached
stdlib.file_line --name memcached.conf/listen --file /etc/memcached.conf --line "-l 0.0.0.0" --match "^-l"
stdlib.sysvinit --name memcached

if [ "$stdlib_state_change" == true ]; then
  /etc/init.d/memcached restart
fi
```

You can create this script inside the Waffles directory (where `waffles.conf` is located), and run it like so:

```shell
bash test.sh
```

When you run it for the first time on a new server, it'll add the group, user, and set up `memcached`. Run it multiple times and note how those same actions were not performed since the script detected that no changes needed to be made.

## Conclusion

At this point, we've effectively recreated the core of Waffles. The rest of controls how Waffles runs and where to find various files that Waffles needs to read.
