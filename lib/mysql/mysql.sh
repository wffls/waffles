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

  if [[ -n "${options[password]}" ]]; then
    stdlib.ini --file "${options[filename]}" --section client --option password --value "${options[password]}"
  fi
}
