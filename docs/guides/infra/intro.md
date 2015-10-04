# Deploying Infrastructure with Waffles

[TOC]

## Description

This series will describe how to deploy infrastructure in a cloud environment using Waffles.

The combination of tools and methods used in this series is only one of many. By swapping out any of the components (even Waffles), you should be able to achieve the same results. In this way, this guide can serve as a general-purpose document for deploying cloud services.

This document will use the following combination of tools and services:

* Cloud Environment: OpenStack, specifically with IPv6 support and a single public subnet
* Cloud Environment: Amazon AWS, specifically for Route53 DNSaaS
* Cloud Infrastructure Deployment: Terraform
* Configuration Management: Waffles
* Operating System: Ubuntu 14.04

## First Steps

### Cloud Access

Make sure you have proper access to the required cloud environments. For this guide, OpenStack and AWS will be used. Make note of the credentials needed to access these environments.

Amazon's Route53 service will be used for DNSaaS. Make sure you have delegated a domain or subdomain to Route53.

### Install Waffles
To begin, first install Waffles to the `/etc/waffles` directory:

```shell
$ cd /etc
$ sudo git clone https://github.com/jtopjian/waffles
```

### Infrastructure Code Directory

Next, create a directory that will be used to hold the infrastructure code:

```shell
$ cd
$ mkdir infrastructure
$ cd infrastructure
```

This directory will have several subdirectories. The first is a `keys` directory to hold SSH keys:

```shell
$ mkdir keys
$ cd keys
$ ssh-keygen -t rsa -N '' -f infra
$ cd ..
```

The next directory is `rc`, which will hold the credentials to the cloud services being used:

```shell
$ mkdir rc
$ cd rc
$ touch openstack
$ touch aws
$ cd ..
```

The third directory is for Waffles. Though Waffles was installed in `/etc/waffles`, this directory will be used to hold the site-specific configuration. By doing this, you can create a whole other infrastructure directory (maybe `infrastructure2`, for a lack of a creative name) that will contain a different set of infrastructure.

```shell
$ mkdir -p waffles/{data,profiles,roles}
```

The fourth directory is for Terraform. This will hold all Terraform configurations:

```shell
$ mkdir terraform
```

### Infrastructure Makefile

This guide will use a `Makefile` to assist with common tasks. Create a file called `Makefile` located in the `infrastructure` directory. We'll add tasks to the `Makefile` as this guide goes on, but for now, start with:

```makefile
WSD = waffles

tplan:
  @. cd terraform/$(ROLE) && terraform plan

tapply:
  @. cd terraform/$(ROLE) && terraform apply

tdestroy:
  @. cd terraform/$(ROLE) && terraform destroy

.PHONY: waffles
waffles:
  WAFFLES_SITE_DIR=$(WSD) /etc/waffles/waffles.sh -s $(NODE) -k keys/infra -r $(ROLE)
```

### Node Inventory

Finally, create a blank file called `nodes`. This will be used to hold an inventory of the deployed nodes:

```shell
$ touch nodes
```

## Foundational Components

Before we start deploying actual services, some foundational pieces need to be created, specifically an OpenStack Security Group and SSH Key Pair.

Create the directory `infrastructure/terraform/support` and in that directory, create the file `main.tf` with the following contents:

```ruby
resource "openstack_compute_keypair_v2" "support" {
  name = "infra"
  public_key = "${file("~/infrastructure/keys/infra.pub")}"
}

resource "openstack_compute_secgroup_v2" "support" {
  name = "AllowAll"
  description = "Group to allow all traffic"

  rule {
    ip_protocol = "tcp"
    from_port = 1
    to_port = 65535
    cidr = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "udp"
    from_port = 1
    to_port = 65535
    cidr = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "icmp"
    from_port = -1
    to_port = -1
    cidr = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port = 1
    to_port = 65535
    cidr = "::/0"
  }
  rule {
    ip_protocol = "udp"
    from_port = 1
    to_port = 65535
    cidr = "::/0"
  }

  rule {
    ip_protocol = "icmp"
    from_port = -1
    to_port = -1
    cidr = "::/0"
  }
}
```

Next, source the `rc/openstack` file and deploy the infrastructure:

```shell
$ source rc/openstack
$ make tplan ROLE=support
$ make tapply ROLE=support
```

At this point, Terraform has deployed the Security Group and Key Pair.

### Common Waffles Settings

When configuring each individual node, a lot of settings will be common amongst all of them. These settings can be added to a single "common" data file called `infrastructure/waffles/data/common.sh`:

```shell
# Declare global variables
declare -ag data_users=()
declare -Ag data_user_info=()
declare -ag data_services=()
declare -Ag data_service_info=()

# Standard node information
declare -Ag data_node_info=()
data_node_info[domain]="example.com"
data_node_info[hostname]=$(hostname)
data_node_info[ip]=$(ip addr show dev eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1)
data_node_info[ip6]=$(ip addr show dev eth0 | grep inet6 | awk '{print $2}' | head -1 | cut -d/ -f1)
data_node_info[nproc]=$(nproc)

# Packages to be installed on all nodes
declare -ag data_packages=()
stdlib.array_push data_packages wget
stdlib.array_push data_packages curl
stdlib.array_push data_packages tmux
stdlib.array_push data_packages vim
stdlib.array_push data_packages iptables

# ACNG server
data_acng_server="acng.example.com"
```

The above script is simply building some hashes and arrays to store common settings. This includes common packages, the node's hostname and domain name, its IPv4 and IPv6 address, and the `apt-cacher-ng` server it should use.

Next, we'll create a "common" profile. This profile will contain scripts that are applicable to any type of node in the environment. First, create the directory structure `infrastructure/waffles/profiles/common/scripts`. And then create the following scripts under it:

#### acng.sh

```shell
stdlib.title "common/acng"

stdlib.file --name /etc/apt/apt.conf.d/01acng --content "Acquire::http { Proxy \"http://$data_acng_server:3142\"; };"
```

#### packages.sh

```shell
stdlib.title "common/packages"

for pkg in "${data_packages[@]}"; do
  stdlib.split $pkg '='
  stdlib.apt --state present --package "${__split[0]}" --version "${__split[1]}"
done
```

#### sudo.sh

```shell
stdlib.title "common/sudo"

stdlib.file_line --name "sudoers.d/00-common/always_set_home" --file /etc/sudoers.d/00-common --line "Defaults always_set_home"
```

#### updates.sh

```shell
stdlib.title "common/updates"

read -r -d '' _security_updates <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
stdlib.file --name /etc/apt/apt.conf.d/20auto-upgrades --content "$_security_updates"
```

#### users.sh

```shell
stdlib.title "common/users"

for user in "${data_users[@]}"; do
  _state="${data_user_info[$user|state]:-present}"
  _username="${data_user_info[$user|name]:-present}"
  _homedir="${data_user_info[$user|homedir]:-""}"
  _uid="${data_user_info[$user|uid]:-""}"
  _gid="${data_user_info[$user|gid]:-""}"
  _comment="${data_user_info[$user|comment]:-""}"
  _shell="${data_user_info[$user|shell]:-""}"
  _passwd="${data_user_info[$user|password]:-""}"
  _create_home="${data_user_info[$user|create_home]:-"true"}"
  _create_group="${data_user_info[$user|create_group]:-"true"}"
  _groups="${data_user_info[$user|groups]:-""}"
  _sudo="${data_user_info[$user|sudo]:-""}"
  _system="${data_user_info[$user|system]:-""}"

  if [[ $_create_group == "true" ]]; then
    stdlib.groupadd --state $_state --group "$_username" --gid "$_gid"
  fi

  stdlib.useradd --state $_state --user "$_username" --uid "$_uid" --gid "$_gid" --comment "$_comment" --homedir "$_homedir" --shell "$_shell" --passwd "$_passwd" --groups "$_groups" --createhome "$_createhome"
done
```

### Augeas

Along with the Waffles Common profile, create a profile that will install and configure Augeas.  Augeas is used to manipulate configuration files that have more difficult styles and formats.

Waffles includes a set of Augeas-based resources, but Waffles does not handle the actual installation and configuration of Augeas.

Create the `infrastructure/waffles/profiles/augeas/scripts` directory and the following scripts:

#### apt_install.sh

```shell
stdlib.title "augeas/apt_install"

stdlib.apt_key --name augeas --key AE498453 --keyserver keyserver.ubuntu.com
stdlib.apt_source --name augeas --uri http://ppa.launchpad.net/raphink/augeas/ubuntu --distribution trusty --component main
stdlib.apt --package augeas-tools --version latest
```

#### update_lenses.sh

```shell
stdlib.title "augeas/update_lenses"

stdlib.git --state latest --name /usr/src/augeas --source https://github.com/hercules-team/augeas

if [[ $stdlib_resource_change == "true" ]]; then
  stdlib.info "Updating lenses"
  stdlib.capture_error cp "/usr/src/augeas/lenses/*.aug" /usr/share/augeas/lenses/dist/
fi
```

### Final Base Directory Structure

At this point, the infrastructure directory should look like this:

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
│   └── support
│       └── main.tf
└── waffles
    ├── data
    │   └── common.sh
    ├── profiles
    │   ├── augeas
    │   │   └── scripts
    │   │       ├── apt_install.sh
    │   │       └── update_lenses.sh
    │   └── common
    │       └── scripts
    │           ├── acng.sh
    │           ├── packages.sh
    │           ├── sudo.sh
    │           ├── updates.sh
    │           └── users.sh
    └── roles
```

You can also reference [this](https://github.com/jtopjian/waffles-infrastructure-guide/tree/intro) Git repository for a snapshot of how everything should look at this point.
