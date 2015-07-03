# == Name
#
# mysql.database
#
# === Description
#
# Manages MySQL databases
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the database. Required. namevar.
# * charset: The character set of the database.
# * collate: The collation of the database.
#
# === Example
#
# ```shell
# mysql.database --name root --password password
# ```
#
function mysql.database {
  stdlib.subtitle "mysql.database"

  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option name    "__required__"
  stdlib.options.create_option charset "utf8"
  stdlib.options.create_option collate "utf8_general_ci"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "mysql.database/${options[name]}"

  local _charset
  local _collate

  mysql.database.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be absent."
      mysql.database.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        mysql.database.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.debug "${options[name]} state: out of date."
        mysql.database.update
        ;;
    esac
  fi
}

function mysql.database.read {

  # TODO
  #local _database_query="SELECT MAX_USER_CONNECTIONS, MAX_CONNECTIONS, MAX_QUESTIONS, MAX_UPDATES, PASSWORD /*!50508 , PLUGIN */ FROM mysql.name WHERE CONCAT(name, '@', host) = '${options[name]}@${options[host]}'"

  local _database_query="SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.schemata WHERE information_schema.schemata.schema_name = '${options[name]}'"
  local _database_result=$(mysql -NBe "${_database_query}")
  if [[ -z "$_database_result" ]]; then
    stdlib_current_state="absent"
    return
  fi

  stdlib.split $_database_result ' '
  _charset="${__split[0]}"
  _collate="${__split[1]}"

  if [[ "$_charset" != "${options[charset]}" ]]; then
    stdlib_current_state="update"
  fi

  if [[ "$_collate" != "${options[collate]}" ]]; then
    stdlib_current_state="update"
  fi

  stdlib_current_state="present"
}

function mysql.database.create {
  stdlib.capture_error  "mysql -NBe \"CREATE DATABASE IF NOT EXISTS \\\`${options[name]}\\\` CHARACTER SET \\\`${options[charset]}\\\` COLLATE \\\`${options[collate]}\\\`\""

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function mysql.database.update {
  if [[ "$_charset" != "${options[charset]}" ]]; then
    stdlib.capture_error "mysql -NBe \"ALTER DATABASE \`${options[name]}\` CHARACTER SET \`${options[charset]}\`\""
  fi

  if [[ "$_collate" != "${options[collate]}" ]]; then
    stdlib.capture_error "mysql -NBe \"ALTER DATABASE \`${options[name]}\` COLLATE \`${options[collate]}\`\""
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function mysql.database.delete {
  stdlib.capture_error "mysql -NBe \"DROP DATABASE IF EXISTS \\\`${options[name]}\\\`\""

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
