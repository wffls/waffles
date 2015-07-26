# == Name
#
# mysql.user
#
# === Description
#
# Manages MySQL users
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The username of the mysql user. unique.
# * host: The host of the mysql user. Required. unique.
# * password: The password of the mysql user.
#
# Unintuitively, user and password are optional because MySQL allows blank usernames and blank passwords.
#
# === Example
#
# ```shell
# mysql.user --user root --password password
# ```
#
function mysql.user {
  stdlib.subtitle "mysql.user"

  # Resource Options
  local -A options
  stdlib.options.create_option state    "present"
  stdlib.options.create_option user     ""
  stdlib.options.create_option host     "__required__"
  stdlib.options.create_option password ""
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[user]}@${options[host]}"
  local password

  # Internal Resource configuration
  if [[ -z ${options[password]} ]]; then
    password=""
  else
    password=$(mysql -NBe "select password('${options[password]}')")
  fi

  # Process the resource
  stdlib.resource.process "mysql.user" "$_name"
}

function mysql.user.read {

  # TODO
  #local _user_query="SELECT MAX_USER_CONNECTIONS, MAX_CONNECTIONS, MAX_QUESTIONS, MAX_UPDATES, PASSWORD /*!50508 , PLUGIN */ FROM mysql.user WHERE CONCAT(user, '@', host) = '${options[user]}@${options[host]}'"

  local _user_query="SELECT count(*) FROM mysql.user WHERE CONCAT(user, '@', host) = '${options[user]}@${options[host]}'"
  local _user_count=$(mysql -NBe "${_user_query}")
  if [[ $_user_count == 0 ]]; then
    stdlib_current_state="absent"
    return
  fi

  local _password_query="SELECT PASSWORD FROM mysql.user WHERE CONCAT(user, '@', host) = '${options[user]}@${options[host]}'"
  local _password=$(mysql -NBe "${_password_query}")
  if [[ $_password != $password ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function mysql.user.create {
  stdlib.capture_error "mysql -NBe \"CREATE USER '${options[user]}'@'${options[host]}' IDENTIFIED BY PASSWORD '${password}'\""
}

function mysql.user.update {
  stdlib.capture_error "mysql -NBe \"SET PASSWORD FOR '${options[user]}'@'${options[host]}' = '${password}'\""
}

function mysql.user.delete {
  stdlib.capture_error "mysql -NBe \"DROP USER '${options[user]}'@'${options[host]}'\""
}
