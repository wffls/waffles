# Waffles!

Waffles is a suite of Bash scripts to manage server resources in in an
idempotent fashion.

## Installation and Usage

To install Waffles, just clone the git repo and source the `init.sh` file:

```bash
$ git clone https://github.com/wffls/waffles /opt/waffles
$ source /opt/waffles/init.sh
$ apt.pkg --help
```

You can integrate Waffles into a Bash script by sourcing the `init.sh` file
within the script:

```bash
#!/bin/bash
source /opt/waffles/init.sh

# Install memcached
apt.pkg --package memcached --version latest

# Set the listen option
file.line --file /etc/memcached.conf --line "-l 0.0.0.0" --match "^-l"

# Determine the amount of memory available and use half of that for memcached
memory_bytes=$(elements System.Memory.Total 2>/dev/null)
memory=$(( $memory_bytes / 1024 / 1024 / 2 ))

# Set the memory available to memcached
file.line --file /etc/memcached.conf --line "-m $memory" --match "^-m"

# Manage the memcached service
service.sysv --name memcached

# If any changes happened, restart memcached
if [[ -n $waffles_total_changes ]]; then
  exec.mute /etc/init.d/memcached restart
fi
```

## Development

Waffles tries to be as simple as possible while still providing useful
utilities for everyday systems administration. If you find a bug or would like
to add a feature, just make a patch and open a Pull Request.

### Testing

Adding unit and acceptance tests are encouraged but not required for Pull
Requests.

Unit tests can be found in `tests/core.sh`. They're mainly used to verify
certain functions work correctly.

Acceptance tests are used to verify resources work correctly.
[Test Kitchen](http://kitchen.ci/) and Docker are used to run the suite of
tests. You can create a testing environment by roughly doing:

```bash
apt-get update
apt-get install -y ruby
wget -qO- https://get.docker.com/
gem install test-kitchen
gem install kitchen-docker
gem install busser-bash
gem install busser-bats
gem install busser-serverspec
kitchen init --driver=kitchen-docker
```

Then execute test suites by:

```bash
$ cd tests/kitchen
$ kitchen test ubuntu1404-ubuntu-1404
```

## More Information

See [waffles.terrarum.net](http://waffles.terrarum.net) for more information.
