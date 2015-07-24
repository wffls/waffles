# Deploying a Consul Cluster

## Description

This recipe will show one way of deploying a Consul cluster with Waffles.

## Steps

### Data

The data file will have the version of Consul to install, a secret key for the cluster, the nodes that are in the cluster, and an associative array of Consul settings.

```shell
$ cat site/data/consul.sh
# Consul Version
data_consul_version="0.5.2"

# Secret key
data_consul_key="jXwOaTXJFf4//4QGrpONBg=="

# Nodes in the cluster
data_consul_nodes=(
  consul-01
  consul-02
  consul-03
)

# Bootstrap node
data_consul_bootstrap_node="consul-03"

# Consul config
declare -Ag data_consul_config
data_consul_config=(
  [server]="true"
  [bootstrap_expect]="${#data_consul_nodes[@]}"
  [client_addr]="0.0.0.0"
  [datacenter]="honolulu"
  [data_dir]="/var/lib/consul"
  [encrypt]="${data_consul_key}"
  [enable_syslog]="true"
  [log_level]="INFO"
)
```

### Profiles

#### Base Packages

In order to successfully execute the other profiles, we'll need to ensure the Consul server has a few base packages installed. Create `site/profiles/common/scripts/packages.sh` with the following contents:

```shell
stdlib.apt --package wget
stdlib.apt --package software-properties-common
```

#### Consul

We'll use two profile scripts for the Consul cluster: the first will install Consul and the second will set up the Consul cluster.

First, make the directory structure

```shell
$ mkdir -p site/profiles/consul/scripts
```

Next, make the repo profile script, located at `site/profiles/consul/scripts/install.sh`:

```shell
stdlib.title "profiles/consul/install"

stdlib.apt --package unzip

stdlib.useradd --user consul --homedir /var/lib/consul --createhome true
stdlib.directory --name /etc/consul.d --owner consul --group consul

if [[ ! -f /usr/local/bin/consul ]]; then
  stdlib.mute pushd /tmp
  stdlib.capture_error wget https://dl.bintray.com/mitchellh/consul/${data_consul_version}_linux_amd64.zip
  stdlib.capture_error unzip ${data_consul_version}_linux_amd64.zip
  stdlib.capture_error mv consul /usr/local/bin
  stdlib.mute popd
fi
```

This install script is rather simple. It's doing the following:

* Installs the `unzip` package
* Creates a `consul` system user with a homedir of `/var/lib/consul`
* Downloads the Consul binary of the version we specified in the data
* Unzips it and installs it to `/usr/local/bin`.

Note: the way this script determines if Consul is installed is by the presence of the `/usr/local/bin/consul` file. If this method is too simplistic for you, feel free to package Consul into a `deb` or `rpm` package.

Next, make the Consul server script, located at `sites/profiles/consul/scripts/server.sh`:

```shell
stdlib.title "profiles/consul/server"

stdlib.file --name /etc/init/consul.conf --source "$WAFFLES_SITE_DIR/profiles/consul/files/consul.conf"

for key in "${!data_consul_config[@]}"; do
  augeas.json_dict --file /etc/consul.d/config.json --path / --key "$key" --value "${data_consul_config[$key]}"
done

stdlib.upstart --name consul --state running

hostname=$(hostname)
if [[ $hostname == $data_consul_bootstrap_node ]]; then
  sleep 10
  for i in "${data_consul_nodes[@]}"; do
    if [[ $hostname != $i ]]; then
      /usr/local/bin/consul join $i
    fi
  done
fi

```

Here are some notes on the above:

* `stdlib.file` is able to copy a static file from `site/profiles/consul/files`. It is _highly_ recommended to bundle your static files into the profile that they are being called from. This ensures that they get copied to the remote node during remote deployment. Alternatively, while there are not yet resources for commands such as `scp` or `wget`, you could use them similarly to how the Consul zip file was downloaded.
* `augeas.json_dict` is an Augeas-based resource that allows JSON files to be built on the command-line. In order to use Augeas, it must be installed. See the next section.
* `stdlib.upstart` ensures that the Consul service is running.
* Finally, the `for` loop will run if the node is the bootstrap node. It'll loop through all other existing nodes and join them. The existing nodes must be up and running first, which is why the bootstrap node was set to the last node in the cluster.

Finally, create `site/profiles/consul/files/consul.conf` with the following content:

```shell
description "Consul agent"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  if [ -f "/etc/default/consul" ]; then
    # Gives us the CONSUL_FLAGS variable
    . /etc/default/consul
  fi

  # Make sure to use all our CPUs, because Consul can block a scheduler thread
  export GOMAXPROCS=`nproc`

  exec /usr/local/bin/consul agent \
    -config-dir="/etc/consul.d" \
    ${CONSUL_FLAGS} \
    >>/var/log/consul.log 2>&1
end script
```

#### Augeas

To install Augeas, create `site/profiles/augeas/scripts/install_apt.sh` with the following content:

```shell
stdlib.title "profiles/augeas/install_apt"

stdlib.apt_ppa --ppa raphink/augeas
stdlib.apt --package augeas-tools --version latest
```

### Roles

Finally, combine the above Data and Profiles to build the role, located at `site/roles/consul.sh`:

```shell
stdlib.enable_augeas

stdlib.data consul

stdlib.profile common/packages
stdlib.profile augeas/install_apt
stdlib.profile consul/install
stdlib.profile consul/server
```

The `stdlib.enable_augeas` function is a special function that will source all of the relevant Augeas functions and resources located under `lib`.

The rest of the role should be self-explanatory.

## Run

You should now run this against 3 servers, containers, or virtual machines of your choice.

## Comments and Conclusion

The above example describes a simple way of deploying a Consul cluster using Waffles. It should be easy enough to modify and add other profiles to make a more well-rounded and robust service for you to use.

Please be aware that `consul-01`, `consul-02`, and `consul-03` are all hostnames that can be resolved. If you are unable to add these to a DNS service, use IP addresses for testing.
