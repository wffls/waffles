# Deploying Consul

[TOC]

## Introduction

To efficiently build and maintain infrastructure, we need to be able to monitor the running nodes, the services they host, and enable them to share information amongst each other. Since this service is so core to the infrastructure, it will be the first service deployed.

This guide will use Consul for this service. Alternatives could be Etcd in combination with Nagios or Sensu.

## Terraform

Let's begin by creating the Terraform structure. First, create the required directories:

```shell
$ mkdir -p terraform/consul/scripts
```

Next, create a small bootstrap script for the Consul nodes that will be launched. Save this script as `terraform/consul/scripts/bootstrap.sh`:

```shell
#!/bin/bash

cp /home/ubuntu/.ssh/authorized_keys /root/.ssh
```

This is just a quick hack to allow us to log into the nodes as the `root` user.

Next, create the `terraform/consul/main.tf` file:

```ruby
variable "count" {
  default = 3
}

resource "openstack_compute_servergroup_v2" "consul" {
  name = "consul"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "consul" {
  count = "${var.count}"
  name = "${format("consul-%02d", count.index+1)}"
  image_name = "Ubuntu 14.04"
  flavor_name = "m1.small"
  key_pair = "infra"
  security_groups = ["AllowAll"]
  config_drive = true
  user_data = "${file("scripts/bootstrap.sh")}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.consul.id}"
  }

  provisioner "local-exec" {
    command = "sed -i -e '/${self.name}/d' ~/infrastructure/nodes && echo ${self.name} ${self.access_ip_v6} consul >> ~/infrastructure/nodes"
  }
}

resource "aws_route53_record" "consul-v6" {
  zone_id = "REPLACEME"
  name = "consul.example.com"
  type = "AAAA"
  ttl = "60"
  records = ["${replace(openstack_compute_instance_v2.consul.*.access_ip_v6, "/[\[\]]/", "")}"]
}

resource "aws_route53_record" "consul-txt" {
  zone_id = "REPLACEME"
  name = "consul.example.com"
  type = "TXT"
  ttl = "60"
  records = ["${formatlist("%s.example.com", openstack_compute_instance_v2.consul.*.name)}"]
}

resource "aws_route53_record" "consul-individual" {
  count = "${var.count}"

  zone_id = "REPLACEME"
  name = "${format("consul-%02d.example.com", count.index+1)}"
  type = "AAAA"
  ttl = "60"
  records = ["${replace(element(openstack_compute_instance_v2.consul.*.access_ip_v6, count.index), "/[\[\]]/", "")}"]
}


resource "null_resource" "consul" {
  count = "${var.count}"

  provisioner "local-exec" {
    command = "sleep 10 && cd ~/infrastructure && make waffles NODE=${element(aws_route53_record.consul-individual.*.name, count.index)} KEY=keys/infra ROLE=consul"
  }
}
```

There's a lot going on here, so let's go over each component. Some of these components will become common to see as they'll be re-used many times in future Terraform configurations.

### Count

```ruby
variable "count" {
  default = 3
}
```

This determines how many nodes will make up the Consul cluster. By default, this configuration will create three, however, you can choose a larger number when Terraform prompts you.

### Server Group

```ruby
resource "openstack_compute_servergroup_v2" "consul" {
  name = "consul"
  policies = ["anti-affinity"]
}
```

A "Server Group" is an OpenStack-specific feature that allows instances (virtual machines / nodes) to have a common policy applied to them. In this case, an "anti-affinity" policy is applied. This ensures that each Consul node is hosted on a different Compute Node. This way, if there's an underlying hardware failure on one of the Compute Nodes in the OpenStack cloud, the entire Consul cluster will not be affected.

### Instance

```ruby
resource "openstack_compute_instance_v2" "consul" {
  count = "${var.count}"
  name = "${format("consul-%02d", count.index+1)}"
  image_name = "Ubuntu 14.04"
  flavor_name = "m1.small"
  key_pair = "infra"
  security_groups = ["AllowAll"]
  config_drive = true
  user_data = "${file("scripts/bootstrap.sh")}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.consul.id}"
  }

  provisioner "local-exec" {
    command = "sed -i -e '/${self.name}/d' ~/infrastructure/nodes && echo ${self.name} ${self.access_ip_v6} consul >> ~/infrastructure/nodes"
  }
}
```

The "Instance" resource is the heart of this configuration. Some notes:

* Notice that there's only one "Instance" defined, but because `count` is set to the "count" variable, three (by default) will be created.
* The name of each instance will take the format `consul-NN` where `NN` is the count in sequence.
* The `user_data` parameter will cause the `scripts/bootstrap.sh` script to run when the instance launches.
* `scheduler_hints` places the instance in the Server Group previously created.

Also note the `local-exec` provisioner. This runs a simple shell command that adds the following pieces of information to `infrastructure/nodes`:
  * name
  * IPv6 Address
  * Role

### DNS Records

```ruby
resource "aws_route53_record" "consul-v6" {
  zone_id = "REPLACEME"
  name = "consul.example.com"
  type = "AAAA"
  ttl = "60"
  records = ["${replace(openstack_compute_instance_v2.consul.*.access_ip_v6, "/[\[\]]/", "")}"]
}

resource "aws_route53_record" "consul-txt" {
  zone_id = "REPLACEME"
  name = "consul.example.com"
  type = "TXT"
  ttl = "60"
  records = ["${formatlist("%s.example.com", openstack_compute_instance_v2.consul.*.name)}"]
}

resource "aws_route53_record" "consul-individual" {
  count = "${var.count}"

  zone_id = "REPLACEME"
  name = "${format("consul-%02d.example.com", count.index+1)}"
  type = "AAAA"
  ttl = "60"
  records = ["${replace(element(openstack_compute_instance_v2.consul.*.access_ip_v6, count.index), "/[\[\]]/", "")}"]
}
```

These three resources create a series of DNS records on Amazon Route53. The first record creates an `AAAA` record called `consul.example.com`. This record contains the IPv6 address of each created Consul node. Since this record holds more than one IP address, Route53 will return each address in a round-robin fashion.

The second DNS record creates a `TXT` record. This record acts as a piece of scratch paper in the DNS system. It holds the hostnames of each created Consul node and will help with bootstrapping Consul.

The third DNS record creates individual `AAAA` records for each of the Consul nodes.

### Provisioner

```ruby
resource "null_resource" "consul" {
  count = "${var.count}"

  provisioner "local-exec" {
    command = "sleep 10 && cd ~/infrastructure && make waffles NODE=${element(aws_route53_record.consul-individual.*.name, count.index)} KEY=keys/infra ROLE=consul"
  }
}
```

The final resource is a "Null" resource. This is a bit of a hack in Terraform to get around the fact that "Provisioners" must be attached to a resource of some type. It's not possible to simply have a "Provisioning" step.

This resource will run the commands in the `command` parameter for each of the created Consul nodes. An example of the rendered command is:

```shell
sleep 10
make waffles NODE=consul-01.example.com KEY=keys/infra ROLE=consul
```

`make` corresponds to the `Makefile` created in the Intro part of this guide. `make waffles` is an actual task that was added to the `Makefile`.

Of course, the Provisioner could have just gone in the Instance resource, but we want _all_ resources to be created before any provisioning begins to take place. In this specific case, it's because we want the DNS records to be populated before Consul is built.

With all of this in place, let's move on to the Waffles side:

## Waffles

### Data

To begin, create a Waffles `data` file to hold the Consul configuration data. This file will be `waffles/data/consul.sh`:

#### consul.sh

```shell
# Tell Waffles about the user and service
stdlib.array_push data_users "consul"
stdlib.array_push data_services "consul"

# Consul Version
data_consul_version="0.5.2"
data_consul_template_version="0.10.0"

# Consul Tokens and Keys
data_consul_encrypt_key="CHANGEME"
data_consul_cluster_name="consul.example.com"

# Describe the user
# This user is added by common/users
data_user_info[consul|name]="consul"
data_user_info[consul|uid]="900"
data_user_info[consul|gid]="900"
data_user_info[consul|homedir]="/var/lib/consul"

# Any extra generic packages
# This package is installed by common/packages
stdlib.array_push data_packages unzip

# Consul config
declare -Ag data_consul_server_config=(
  [server]="true"
  [advertise_addr]="${data_node_info[ip6]}"
  [client_addr]="127.0.0.1"
  [bind_addr]="0.0.0.0"
  [bootstrap_expect]="3"
  [datacenter]="honolulu"
  [data_dir]="/var/lib/consul"
  [encrypt]="${data_consul_encrypt_key}"
  [enable_syslog]="true"
  [log_level]="INFO"
  [rejoin_after_leave]="true"
  [retry_interval]="30s"
  [ui_dir]="/opt/consul-web/dist"
)

declare -Ag data_consul_client_config=(
  [advertise_addr]="${data_node_info[ip6]}"
  [client_addr]="127.0.0.1"
  [datacenter]="honolulu"
  [data_dir]="/var/lib/consul"
  [encrypt]="${data_consul_encrypt_key}"
  [enable_syslog]="true"
  [log_level]="INFO"
  [rejoin_after_leave]="true"
  [retry_interval]="30s"
)

declare -Ag data_consul_template_config=(
  [global|consul]="localhost:8500"
  [global|retry]="10s"
  [global|max_stale]="10m"
  [global|log_level]="INFO"
  [syslog|enabled]="true"
  [syslog|facility]="LOCAL5"
)
```

### Profile

Next, create the Consul profile. Start with the directory structure: `waffles/profiles/consul/scripts`. Inside `scripts`, create the following scripts:

#### client.sh

```shell
stdlib.title "consul/client"

_user="${data_user_info[consul|name]}"

# Consul Directories
stdlib.directory --name /var/lib/consul --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul/agent --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul/agent/conf.d --owner $_user --group $_user --mode 750
stdlib.file --name /var/log/consul.log --owner $_user --group $_user --mode 640

# Install Consul
if [[ ! -f /usr/local/bin/consul ]]; then
  stdlib.mute pushd /tmp
    stdlib.capture_error wget https://dl.bintray.com/mitchellh/consul/${data_consul_version}_linux_amd64.zip
    stdlib.capture_error unzip ${data_consul_version}_linux_amd64.zip
    stdlib.capture_error mv consul /usr/local/bin
  stdlib.mute popd
fi

# Configure Consul
for key in "${!data_consul_client_config[@]}"; do
  augeas.json_dict --file "/etc/consul/agent/conf.d/config.json" --path / --key "$key" --value "${data_consul_client_config[$key]}"
done

augeas.json_array --file "/etc/consul/agent/conf.d/config.json" --path / --key "retry_join" --value "$data_consul_cluster_name"

# Consul Service
stdlib.file --name /etc/init/consul.conf --source "$WAFFLES_SITE_DIR/profiles/consul/files/consul.conf"
stdlib.upstart --name consul --state running
```

#### server.sh

```shell
stdlib.title "consul/server"

_user="${data_user_info[consul|name]}"

# Consul Directories
stdlib.directory --name /var/lib/consul --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul/agent --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul/agent/conf.d --owner $_user --group $_user --mode 750
stdlib.directory --name /opt/consul-web --owner $_user --group $_user --mode 750
stdlib.file --name /var/log/consul.log --owner $_user --group $_user --mode 640

# Install Consul
if [[ ! -f /usr/local/bin/consul ]]; then
  stdlib.mute pushd /tmp
    stdlib.capture_error wget https://dl.bintray.com/mitchellh/consul/${data_consul_version}_linux_amd64.zip
    stdlib.capture_error unzip ${data_consul_version}_linux_amd64.zip
    stdlib.capture_error mv consul /usr/local/bin
  stdlib.mute popd
fi

# Configure Consul
for key in "${!data_consul_server_config[@]}"; do
  augeas.json_dict --file "/etc/consul/agent/conf.d/config.json" --path / --key "$key" --value "${data_consul_server_config[$key]}"
done

for attempt in {1..10}; do
  _nodes=($(dig +short -t txt $data_consul_cluster_name | sort | tr -d \"))
  if [[ -z "$_nodes" ]]; then
    stdlib.warn "No consul nodes found. Sleeping"
    sleep 60
  else
    break
  fi
done

for _node in "${_nodes[@]}"; do
  _consul_nodes="${_consul_nodes}--value ${_node} "
done

augeas.json_array --file "/etc/consul/agent/conf.d/config.json" --path / --key "retry_join" $_consul_nodes

stdlib.file --name /usr/local/bin/purge_failed.sh --mode "750" --source "$WAFFLES_SITE_DIR/profiles/consul/files/purge_failed.sh"
stdlib.cron --name consul_purge_failed_nodes --cmd /usr/local/bin/purge_failed.sh

# Server nodes get the web UI
if [[ ! -d /opt/consul-web/dist ]]; then
  stdlib.mute pushd /tmp
    stdlib.capture_error wget https://dl.bintray.com/mitchellh/consul/${data_consul_version}_web_ui.zip
    stdlib.capture_error unzip -d /opt/consul-web ${data_consul_version}_web_ui.zip
    stdlib.capture_error chown -R consul: /opt/consul-web
  stdlib.mute popd
fi

# Consul Service
stdlib.file --name /etc/init/consul.conf --source "$WAFFLES_SITE_DIR/profiles/consul/files/consul.conf"
stdlib.upstart --name consul --state running
```

The unique thing about this script is the use of polling the `TXT` file created by Terraform. In order for Consul to bootstrap itself, it needs to first know of a few neighboring nodes. By polling the `TXT` record, it can get a list of those nodes.

#### template.sh

```shell
stdlib.title "consul/template"

_user="${data_user_info[consul|name]}"

# Consul Template Directories
stdlib.directory --name /etc/consul/template --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul/template/ctmpl --owner $_user --group $_user --mode 750
stdlib.directory --name /etc/consul/template/conf.d --owner $_user --group $_user --mode 750
stdlib.file --name /var/log/consul-template.log --owner root --group syslog --mode 640
stdlib.file --name /etc/init/consul-template.conf --source "$WAFFLES_SITE_DIR/profiles/consul/files/consul-template.conf"

if [[ ! -f /usr/local/bin/consul-template ]]; then
  stdlib.mute pushd /tmp
    stdlib.capture_error wget https://github.com/hashicorp/consul-template/releases/download/v${data_consul_template_version}/consul-template_${data_consul_template_version}_linux_amd64.tar.gz
    stdlib.capture_error tar xzvf consul-template_${data_consul_template_version}_linux_amd64.tar.gz
    stdlib.capture_error mv consul-template_${data_consul_template_version}_linux_amd64/consul-template /usr/local/bin
  stdlib.mute popd
fi

for key in "${!data_consul_template_config[@]}"; do
  stdlib.split $key "|"
  _section="${__split[0]}"
  _option="${__split[1]}"

  if [[ $_section == "global" ]]; then
    augeas.json_dict --file "/etc/consul/template/conf.d/config.json" --path / --key "$_option" --value "${data_consul_template_config[$key]}"
  else
    augeas.json_dict --file "/etc/consul/template/conf.d/config.json" --path "/$_section" --key "$_option" --value "${data_consul_template_config[$key]}"
  fi
done

stdlib.upstart --name consul-template --state running
```

The above script sets up [Consul Template](https://github.com/hashicorp/consul-template)

#### template-hosts.sh

```shell
stdlib.title "consul/template_hosts"

consul.template --name hosts --destination /etc/hosts
stdlib.file --name /etc/consul/template/ctmpl/hosts.ctmpl --mode 640 --source "$WAFFLES_SITE_DIR/profiles/consul/files/hosts.ctmpl"

if [[ $stdlib_state_change == "true" ]]; then
  restart consul-template
fi
```

The above script configures the `/etc/hosts` file to be populated by the nodes that Consul knows about.

#### Files

The above scripts reference some static files that need to be installed on the nodes. For brevity, you can find these scripts in the Git repo linked at the end of this document.

### Role

With the Consul Data and Profile in place, it's time to build the role. Create the file `waffles/roles/consul.sh` with the following contents:

```shell
stdlib.enable_augeas
stdlib.enable_consul

stdlib.data common
stdlib.data consul

stdlib.profile common/acng
stdlib.profile common/packages
stdlib.profile common/users
stdlib.profile common/updates
stdlib.profile common/sudo

stdlib.profile augeas/apt_install
stdlib.profile augeas/update_lenses

stdlib.profile consul/server
stdlib.profile consul/template
stdlib.profile consul/template_hosts
```

The `stdlib.enable_augeas` and `stdlib.enable_consul` commands are built-in to Waffles. They enable augeas and consul-specific functions and resources. See the Waffles documentation for more information.

The rest of the role should be self-explanatory: the `common` and `consul` data files are being read, then the `common`, `augeas` and `consul` profiles. Everything combined makes up a unique "Consul" role.

## Deploying

To deploy the cluster, do the following:

```shell
$ make tplan ROLE=consul
$ make tapply ROLE=consul
```

If everything was successful, you should have a running Consul cluster. You can verify this by doing:

```shell
$ ssh -i keys/infra consul.example.com
$ consul status
```

## Consul Key-Value Storage

Consul was setup in a way that restricts access to the key-value store to only nodes running Consul. Terraform provides a `consul_keys` resource that can store data from the Terraform configuration in Consul. Rather than installing Consul on your workstation, an alternative is to SSH into the Consul cluster and forward the port 8500. To do this, make a new task in the `Makefile` called `ctunnel`:

```makefile
ctunnel:
  ssh -i keys/infra -L 8500:localhost:8500 consul.example.com
```

Now run the task:

```shell
$ make ctunnel
```

You should now have forwarded access to your Consul cluster.

## Conclusion

This part of the Infrastructure guide detailed how to deploy a Consul cluster. At this point, your directory structure should look like:

```shell
infrastructure
├── keys
│   ├── infra
│   └── infra.pub
├── Makefile
├── nodes
├── rc
│   ├── aws
│   └── openstack
├── terraform
│   ├── consul
│   │   ├── main.tf
│   │   └── scripts
│   │       └── bootstrap.sh
│   └── support
│       └── main.tf
└── waffles
    ├── data
    │   ├── common.sh
    │   └── consul.sh
    ├── profiles
    │   ├── augeas
    │   │   └── scripts
    │   │       ├── apt_install.sh
    │   │       └── update_lenses.sh
    │   ├── common
    │   │   └── scripts
    │   │       ├── acng.sh
    │   │       ├── packages.sh
    │   │       ├── sudo.sh
    │   │       ├── updates.sh
    │   │       └── users.sh
    │   └── consul
    │       ├── files
    │       │   ├── consul.conf
    │       │   ├── consul-template.conf
    │       │   ├── hosts.ctmpl
    │       │   └── purge_failed.sh
    │       └── scripts
    │           ├── client.sh
    │           ├── server.sh
    │           ├── template_hosts.sh
    │           └── template.sh
    └── roles
        └── consul.sh
```

You can find the final scripts and structure [here](https://github.com/jtopjian/waffles-infrastructure-guide/tree/consul).
