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
# * name: The name of the database. Required.
# * charset: The character set of the database.
# * collate: The collation of the database.
#
# === Example
#
# ```shell
# mysql.database --name mydb
# ```
#
function mysql.database {
  # Declare the resource
  waffles_resource="mysql.database"

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option name    "__required__"
  waffles.options.create_option charset "utf8"
  waffles.options.create_option collate "utf8_general_ci"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _charset
  local _collate

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

function mysql.database.read {

  # TODO
  #local _database_query="SELECT MAX_USER_CONNECTIONS, MAX_CONNECTIONS, MAX_QUESTIONS, MAX_UPDATES, PASSWORD /*!50508 , PLUGIN */ FROM mysql.name WHERE CONCAT(name, '@', host) = '${options[name]}@${options[host]}'"

  local _database_query="SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.schemata WHERE information_schema.schemata.schema_name = '${options[name]}'"
  local _database_result=$(mysql -NBe "${_database_query}")
  if [[ -z $_database_result ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  string.split $_database_result ' '
  _charset="${__split[0]}"
  _collate="${__split[1]}"

  if [[ $_charset != ${options[charset]} ]]; then
    waffles_resource_current_state="update"
  fi

  if [[ $_collate != ${options[collate]} ]]; then
    waffles_resource_current_state="update"
  fi

  waffles_resource_current_state="present"
}

function mysql.database.create {
  exec.capture_error  "mysql -NBe \"CREATE DATABASE IF NOT EXISTS \\\`${options[name]}\\\` CHARACTER SET \\\`${options[charset]}\\\` COLLATE \\\`${options[collate]}\\\`\""
}

function mysql.database.update {
  if [[ $_charset != ${options[charset]} ]]; then
    exec.capture_error "mysql -NBe \"ALTER DATABASE \`${options[name]}\` CHARACTER SET \`${options[charset]}\`\""
  fi

  if [[ $_collate != ${options[collate]} ]]; then
    exec.capture_error "mysql -NBe \"ALTER DATABASE \`${options[name]}\` COLLATE \`${options[collate]}\`\""
  fi
}

function mysql.database.delete {
  exec.capture_error "mysql -NBe \"DROP DATABASE IF EXISTS \\\`${options[name]}\\\`\""
}
