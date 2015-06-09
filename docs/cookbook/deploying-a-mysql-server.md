# Deploying a MySQL Server

## Description

This recipe will show one way of deploying a MySQL server with Waffles. In particular, Percona MySQL.

## Steps

### Data

There will only be one data item: the MySQL root password. This example will store the password in plain text -- note that a best practice would be to install it either in an encrypted repository, an encrypted string, or something along those lines.

```shell
$ cat site/data/mysql.sh
data_mysql_root_password="password"
```

### Profiles

We'll use two profile scripts for the MySQL server: the first will configure the Percona repo and the second will install and configure MySQL itself.

First, make the directory structure

```shell
$ mkdir -p site/profiles/mysql/scripts
```

Next, make the repo profile script, located at `site/profiles/mysql/scripts/percona_repo.sh`:

```shell
stdlib.title "mysql/percona/repo"

source /etc/lsb-release

stdlib.apt_key --name percona --keyserver keys.gnupg.net --key 1C4CBDCDCD2EFD2A
stdlib.apt_source --name percona --uri http://repo.percona.com/apt --distribution $DISTRIB_CODENAME --component main --include_src true
```

Next, make the MySQL profile script, located at `sites/profilfes/mysql/scripts/percona_server.sh`:

```shell
stdlib.title "mysql/percona/server"

hostname=$(hostname | sed -e 's/_/\\\_/g')

stdlib.apt --package percona-server-server-5.6

mysql.user --user root --host localhost --password password
mysql.mycnf --filename "/root/.my.cnf" --user root --password password

mysql.user --state absent --user root --host 127.0.0.1 --password ""
mysql.user --state absent --user root --host ::1 --password ""
mysql.user --state absent --user "" --host localhost --password ""
mysql.user --state absent --user root --host $hostname --password ""
mysql.user --state absent --user "" --host $hostname --password ""

mysql.database --state absent --name test

stdlib.ini --file /etc/mysql/my.cnf --section mysqld --option bind-address --value 0.0.0.0

if [[ $stdlib_state_change == true ]]; then
  /etc/init.d/mysql restart
fi
```

This script is rather simple in concept. Some notes about it:

* The `hostname` variable is doing some shell escaping for MySQL commands.
* A `root@localhost` user is being configured with the password set in the data file.
* MySQL installs several other default `root` and "blank" users. We want to ensure these users are removed.
* We also want to ensure that the `test` database is removed.
* MySQL listens on localhost by default. We want it to listen on all interfaces, so we change the `bind-address` setting to `0.0.0.0`.
* The special variable `$stdlib_state_change` will be `true` if any changes were made at all in the file. If they were, we want to restart the MySQL service. This will not happen if no changes were made.

### Roles

Finally, combine the above Data and Profiles to build the role, located at `site/roles/mysql.sh`:

```shell
stdlib.enable_mysql

stdlib.data mysql

stdlib.profile mysql/percona_repo
stdlib.profile mysql/percona_server
```

The `stdlib.enable_mysql` function is a special function that will source all of the relevant MySQL functions and resources located under `lib`.

The rest of the role should be self-explanatory.

## Comments and Conclusion

The above example describes a simple way of deploying a Percona MySQL server using Waffles. It should be easy enough to modify and add other profiles to make a more well-rounded and robust service for you to use.
