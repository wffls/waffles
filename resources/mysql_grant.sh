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
mysql.grant() {
  # Declare the resource
  waffles_resource="mysql.grant"

  # Resource Options
  local -A options
  waffles.options.create_option state      "present"
  waffles.options.create_option user       "__required__"
  waffles.options.create_option host       "__required__"
  waffles.options.create_option database   "__required__"
  waffles.options.create_option privileges "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


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
  waffles.resource.process $waffles_resource "$_name"
}

mysql.grant.read() {

  # TODO: Better handling of privileges

  local _grant_query="SHOW GRANTS FOR $_name"
  local _grant_result=$(mysql -NBe "${_grant_query}" 2>/dev/null | grep -v USAGE | grep -v PROXY)
  if [[ -z $_grant_result ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  waffles_resource_current_state="update"
  while IFS= read -r _line ; do
    if [[ $_line =~ ^$_grant ]]; then
      waffles_resource_current_state="present"
      return
    fi
  done <<< "$_grant_result"

}

mysql.grant.create() {
  exec.capture_error "mysql -NBe \"GRANT ${options[privileges]} on ${options[database]}.* to $_name\""
}

mysql.grant.update() {
  mysql.grant.delete
  mysql.grant.create
}

mysql.grant.delete() {
  exec.capture_error "mysql -NBe \"REVOKE GRANT OPTION ON ${options[database]}.* FROM $_name\""
  exec.capture_error "mysql -NBe \"REVOKE ALL ON ${options[database]}.* FROM $_name\""
}
