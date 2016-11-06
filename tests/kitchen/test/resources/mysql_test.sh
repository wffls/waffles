setup() {
  apt-get update
  #dpkg.debconf --package mysql-server --question mysql-server/root_password --vtype select --value password
  #dpkg.debconf --package mysql-server --question mysql-server/root_password_again --vtype select --value password
  apt.pkg --name mysql-server
  exec.capture_error /etc/init.d/mysql restart
  #mysql.mycnf --filename /root/.my.cnf --user root --password password
  sleep 5
}

create() {
  mysql.database --name db1
  mysql.user --user user1 --host localhost --password password
  mysql.grant --user user1 --host localhost --database db1 --privileges SELECT
}

update() {
  mysql.user --user user1 --host localhost --password password2
  mysql.grant --user user1 --host localhost --database db1 --privileges ALL
}

delete() {
  mysql.database --state absent --name db1
  mysql.user --state absent --user user1 --host localhost --password password
  mysql.grant --state absent --user user1 --host localhost --database db1 --privileges SELECT
}

teardown() {
  return
}
