# Deploying a MySQL Galera Cluster

[TOC]

## Description

This guide will show one way of deploying a MySQL Galera cluster with Waffles. In particular, Percona XtraDB Cluster.

## Steps

### Data

The data file will contain a few items:

* The MySQL root password
* The SST password
* The name of the node which will act as the "bootstrap" node.

This example will store the password in plain text -- note that a best practice would be to install it either in an encrypted repository, an encrypted string, or something along those lines.

```shell
$ cat site/data/mysql.sh
data_mysql_root_password="password"
data_mysql_sst_password="password"
data_galera_bootstrap_node="mysql-01"
```

### Profiles

We'll use two profile scripts for the Galera cluster: the first will configure the Percona repo and the second will install and configure MySQL and Galera.

First, make the directory structure

```shell
$ mkdir -p site/profiles/mysql/scripts
```

Next, make the repo profile script, located at `site/profiles/mysql/scripts/percona_repo.sh`:

```shell
source /etc/lsb-release

apt.key --name percona --keyserver keys.gnupg.net --key 1C4CBDCDCD2EFD2A
apt.source --name percona --uri http://repo.percona.com/apt --distribution $DISTRIB_CODENAME --component main --include_src true
```

Next, make the MySQL profile script, located at `sites/profiles/mysql/scripts/percona_xtradb_cluster.sh`:

```shell
# Get some information useful for the configuration
hostname=$(hostname)
mysql_hostname=$(hostname | sed -e 's/_/\\\_/g')
my_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

# Install the percona cluster package
apt.pkg --package percona-xtradb-cluster-56

# Record of the MySQL sysv service
service.sysv --name mysql

# Configure the MySQL root user
mysql.user --user root --host localhost --password "$data_mysql_root_password"
mysql.mycnf --filename "/root/.my.cnf" --user root --password "$data_mysql_root_password"

# Remove some of the default accounts
mysql.user --state absent --user root --host 127.0.0.1 --password ""
mysql.user --state absent --user root --host ::1 --password ""
mysql.user --state absent --user "" --host localhost --password ""
mysql.user --state absent --user root --host $mysql_hostname --password ""
mysql.user --state absent --user "" --host $mysql_hostname --password ""

# Create the sst user
mysql.user --user sst --host localhost --password "$data_mysql_sst_password"
mysql.grant --user sst --host localhost --database "*" --privileges "RELOAD, LOCK TABLES, REPLICATION CLIENT"

# Configure `/etc/mysql/my.cnf`
file.ini --file /etc/mysql/my.cnf --section mysqld --option wsrep_provider --value /usr/lib/libgalera_smm.so
file.ini --file /etc/mysql/my.cnf --section mysqld --option wsrep_sst_method --value xtrabackup-v2
file.ini --file /etc/mysql/my.cnf --section mysqld --option binlog_format --value ROW
file.ini --file /etc/mysql/my.cnf --section mysqld --option default_storage_engine --value InnoDB
file.ini --file /etc/mysql/my.cnf --section mysqld --option innodb_autoinc_lock_mode --value 2
file.ini --file /etc/mysql/my.cnf --section mysqld --option wsrep_node_address --value $my_ip
file.ini --file /etc/mysql/my.cnf --section mysqld --option wsrep_cluster_name --value my_cluster
file.ini --file /etc/mysql/my.cnf --section mysqld --option wsrep_sst_auth --value "sst:${data_mysql_sst_password}"

# If the hostname is config_galera1, do not set gcomm
if [[ $hostname == $data_galera_bootstrap_node ]]; then
  file.ini --file /etc/mysql/my.cnf --section mysqld --option wsrep_cluster_address --value "gcomm://"
else
  file.ini --file /etc/mysql/my.cnf --section mysqld --option wsrep_cluster_address --value "gcomm://mysql-01,mysql-02,mysql-03"
fi

# If any of the above settings changed, restart MySQL
if [[ $waffles_state_changed == true ]]; then
  /etc/init.d/mysql restart
fi
```

This script may be a little long, but it shouldn't be difficult to understand. Some notes about it:

* The `hostname` is captured to determine if the node should be the bootstrap node. It's also used for some MySQL configuration.
* A `root@localhost` user is being configured with the password set in the data file.
* MySQL installs several other default `root` and "blank" users. We want to ensure these users are removed.
* We also want to ensure that the `test` database is removed.
* MySQL listens on localhost by default. We want it to listen on all interfaces, so we change the `bind-address` setting to `0.0.0.0`.
* The `file.ini` resources are configuring MySQL, wsrep, and SST.
* If the node is the bootstrap node, the `wsrep_cluster_address` is set to the special `gcomm://`. If not, it is set to all other nodes in the cluster. Once the cluster has been bootstrapped, you should remove the `if` conditional and only leave the `else` portion.
* The special variable `$waffles_state_changed` will be `true` if any changes were made at all in the file. If they were, we want to restart the MySQL service. This will not happen if no changes were made.

### Roles

Finally, combine the above Data and Profiles to build the role, located at `site/roles/mysql.sh`:

```shell
waffles.data mysql

waffles.profile mysql/percona_repo
waffles.profile mysql/percona_xtradb_cluster
```

The rest of the role should be self-explanatory.

## Run

You should now run this against 3 servers, containers, or virtual machines of your choice. The bootstrap node must be run and completed before all others.

## Comments and Conclusion

The above example describes a simple way of deploying a Percona MySQL Galera cluster using Waffles. It should be easy enough to modify and add other profiles to make a more well-rounded and robust service for you to use.

Please be aware that `mysql-01`, `mysql-02`, and `mysql-03` are all hostnames that can be resolved. If you are unable to add these to a DNS service, use IP addresses for testing.
