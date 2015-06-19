# Waffles!

Waffles is a simple configuration management and deployment system written in Bash.

```shell
stdlib.title profiles/memcached/server

# Install memcached
stdlib.apt --package memcached --version latest

# Set the listen option
stdlib.file_line --name memcached.conf/listen --file /etc/memcached.conf --line "-l $data_memcached_server_listen" --match "^-l"

# Determine the amount of memory available and use half of that for memcached
memory_bytes=$(cfacter memory.system.total_bytes 2>/dev/null)
memory=$(( $memory_bytes / 1024 / 1024 / 2 ))

# Set the memory available to memcached
stdlib.file_line --name memcached.conf/memory --file /etc/memcached.conf --line "-m $memory" --match "^-m"

# Manage the memcached service
stdlib.sysvinit --name memcached

if [[ $stdlib_state_change == true ]]; then
  stdlib.mute /etc/init.d/memcached restart
fi
```

See [waffles.terrarum.net](http://waffles.terrarum.net) for more information.
