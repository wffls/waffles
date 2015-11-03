# == Name
#
# mysql.grant
#
# === Description
#
# Manages MySQL grants
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The user to receive the grant. Required. unique.
# * host: The host of the user. Required. unique.
# * database: The database to apply the grant on. Required.
# * privileges: The privileges to grant. Required.
#
# === Example
#
# ```shell
# mysql.grant --user nova --host localhost --database nova --privileges "SELECT, UPDATE, DELETE"
# ```
#
function mysql.grant {
  stdlib.subtitle "mysql.grant"

  # Resource Options
  local -A options
  stdlib.options.create_option state      "present"
  stdlib.options.create_option user       "__required__"
  stdlib.options.create_option host       "__required__"
  stdlib.options.create_option database   "__required__"
  stdlib.options.create_option privileges "__required__"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="'${options[user]}'@'${options[host]}'"
  local _grant
  local _privileges

  # Internal Resource Configuration
  if [[ "${options[privileges]}" == "ALL" ]]; then
    _privileges="ALL PRIVILEGES"
  else
    _privileges="${options[privileges]}"
  fi

  if [[ ${options[database]} == "*" ]]; then
    _grant="GRANT $_privileges ON *.* TO $_name"
  else
    _grant="GRANT $_privileges ON \`${options[database]}\`.* TO $_name"
  fi

  # Process the resource
  stdlib.resource.process "mysql.grant" "$_name"
}

function mysql.grant.read {

  # TODO: Better handling of privileges

  local _grant_query="SHOW GRANTS FOR $_name"
  local _grant_result=$(mysql -NBe "${_grant_query}" 2>/dev/null | grep -v USAGE | grep -v PROXY)
  if [[ -z $_grant_result ]]; then
    stdlib_current_state="absent"
    return
  fi

  if [[ ! $_grant_result =~ ^$_grant ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function mysql.grant.create {
  stdlib.capture_error "mysql -NBe \"GRANT ${options[privileges]} on ${options[database]}.* to $_name\""
}

function mysql.grant.update {
  mysql.grant.delete
  mysql.grant.create
}

function mysql.grant.delete {
  stdlib.capture_error "mysql -NBe \"REVOKE GRANT OPTION ON ${options[database]}.* FROM $_name\""
  stdlib.capture_error "mysql -NBe \"REVOKE ALL ON ${options[database]}.* FROM $_name\""
}
