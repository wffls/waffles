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

  local -A options
  stdlib.options.set_option state    "present"
  stdlib.options.set_option user     ""
  stdlib.options.set_option host     "__required__"
  stdlib.options.set_option password ""
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "mysql.user/${options[user]}@${options[host]}"

  local password
  if [[ -z "${options[password]}" ]]; then
    password=""
  else
    password=$(mysql -NBe "select password('${options[password]}')")
  fi

  mysql.user.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[user]} state: $stdlib_current_state, should be absent."
      mysql.user.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[user]} state: absent, should be present."
        mysql.user.create
        ;;
      present)
        stdlib.debug "${options[user]} state: present."
        ;;
      update)
        stdlib.debug "${options[user]} state: out of date."
        mysql.user.update
        ;;
    esac
  fi
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

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function mysql.user.update {
  stdlib.capture_error "mysql -NBe \"SET PASSWORD FOR '${options[user]}'@'${options[host]}' = '${password}'\""

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function mysql.user.delete {
  stdlib.capture_error "mysql -NBe \"DROP USER '${options[user]}'@'${options[host]}'\""

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
