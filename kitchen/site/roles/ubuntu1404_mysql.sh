source /etc/lsb-release

stdlib.enable_mysql

stdlib.apt_key --name percona --keyserver keys.gnupg.net --key 1C4CBDCDCD2EFD2A
stdlib.apt_source --name percona --uri http://repo.percona.com/apt --distribution $DISTRIB_CODENAME --component main --include_src true

hostname=$(hostname | sed -e 's/_/\\\_/g')

stdlib.apt --package percona-server-server-5.6

stdlib.ini --file /etc/mysql/my.cnf --section mysqld --option bind-address --value 0.0.0.0

if [[ $stdlib_state_change == true ]]; then
  /etc/init.d/mysql restart
fi

sleep 20

mysql.user --user root --host localhost --password password
mysql.mycnf --filename "/root/.my.cnf" --user root --password password
mysql.mycnf --filename "/home/kitchen/.my.cnf" --user root --password password

mysql.database --state absent --name test
mysql.user --state absent --user root --host 127.0.0.1 --password ""
mysql.user --state absent --user root --host ::1 --password ""
mysql.user --state absent --user "" --host localhost --password ""
mysql.user --state absent --user root --host $hostname --password ""
mysql.user --state absent --user "" --host $hostname --password ""

