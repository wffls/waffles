mysql.database_exists() {
  if [[ $# -gt 0 ]]; then
    log.debug "Checking if MySQL Database $1 exists."
    local _database_query="SELECT count(*) FROM information_schema.schemata WHERE information_schema.schemata.schema_name = '$1'"
    local _database_result=$(mysql -NBe "${_database_query}")
    if [[ $_database_result == "0" ]]; then
      return 1
    else
      return 0
    fi
  fi
}

mysql.mycnf() {
  local -A options
  waffles.options.create_option state      "present"
  waffles.options.create_option filename   "__required__"
  waffles.options.create_option file_owner "root"
  waffles.options.create_option file_group "root"
  waffles.options.create_option user       "__required__"
  waffles.options.create_option socket     "/var/run/mysqld/mysqld.sock"
  waffles.options.create_option host
  waffles.options.create_option password
  waffles.options.parse_options "$@"

  if [[ ! -f "${options[filename]}" ]]; then
    os.file --name "${options[filename]}" --owner "${options[file_owner]}" --group "${options[file_group]}" --mode 0640
  fi

  file.ini --file "${options[filename]}" --section client --option user --value "${options[user]}"
  if [[ -n "${options[host]}" ]]; then
    file.ini --file "${options[filename]}" --section client --option host --value "${options[host]}"
  else
    file.ini --file "${options[filename]}" --section client --option socket --value "${options[socket]}"
  fi

  if [[ -n ${options[password]} ]]; then
    file.ini --file "${options[filename]}" --section client --option password --value "${options[password]}"
  fi
}
