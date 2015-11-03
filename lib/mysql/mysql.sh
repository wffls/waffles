function mysql.admin_password_set? {
  stdlib.debug "Checking if the admin password is set."
  mysql -e "select now()" &>/dev/null
  if [[ $? == 0 ]]; then
    stdlib.debug "No password set on MySQL server."
    return 1
  else
    stdlib.debug "Password set on MySQL server."
    return 0
  fi
}

function mysql.database_exists? {
  if [[ $# -gt 0 ]]; then
    stdlib.debug "Checking if MySQL Database $1 exists."
    local _database_query="SELECT count(*) FROM information_schema.schemata WHERE information_schema.schemata.schema_name = '$1'"
    local _database_result=$(mysql -NBe "${_database_query}")
    if [[ $_database_result == "0" ]]; then
      return 1
    else
      return 0
    fi
  fi
}

function mysql.mycnf {
  local -A options
  stdlib.options.create_option state    "present"
  stdlib.options.create_option filename "__required__"
  stdlib.options.create_option user     "__required__"
  stdlib.options.create_option host     "localhost"
  stdlib.options.create_option socket   "/var/run/mysqld/mysqld.sock"
  stdlib.options.create_option password
  stdlib.options.parse_options "$@"

  stdlib.ini --file "${options[filename]}" --section client --option user --value "${options[user]}"
  stdlib.ini --file "${options[filename]}" --section client --option host --value "${options[host]}"
  stdlib.ini --file "${options[filename]}" --section client --option socket --value "${options[socket]}"

  if [[ -n ${options[password]} ]]; then
    stdlib.ini --file "${options[filename]}" --section client --option password --value "${options[password]}"
  fi
}
