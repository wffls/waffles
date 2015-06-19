`lib/mysql/mysql.sh` contains helper functions for the MySQL resources

## mysql.admin_password_set?

A simple function that checks if the MySQL service has an admin password set.

## mysql.mycnf

A function that generates a `.my.cnf` file.

```shell
mysql.mycnf --filename "/root/.my.cnf" --user root --password password
```

This isn't a first-class resource because it simply builds on other resources.
