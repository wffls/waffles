# == Name
#
# nginx.if
#
# === Description
#
# Manages key/value settings in an nginx server if block
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The conditional of the if block. Required. namevar.
# * server_name: The name of the nginx_server resource. Required.
# * key: The key. Required.
# * value: A value for the key. Required.
# * file: The file to add the variable to. Optional. Defaults to /etc/nginx/sites-enabled/server_name.
#
# === Example
#
# ```shell
# nginx.if --name '$request_method !~ ^(GET|HEAD|POST)$' --server_name example.com --key return --value 444
# ```
#
function nginx.if {
  stdlib.subtitle "nginx.if"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state       "present"
  stdlib.options.create_option name        "__required__"
  stdlib.options.create_option server_name "__required__"
  stdlib.options.create_option key         "__required__"
  stdlib.options.create_option value       "__required__"
  stdlib.options.create_option file
  stdlib.options.parse_options "$@"

  local _name="${options[name]}.${options[key]}"
  stdlib.catalog.add "nginx.if/$_name"

  local _dir="/etc/nginx/sites-enabled"
  local _server_name="${options[server_name]}"
  local _cond="(${options[name]})"
  local _file

  if [[ -n "${options[file]}" ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/${_server_name}"
  fi

  nginx.if.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      nginx.if.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        nginx.if.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        nginx.if.update
        ;;
      error)
        stdlib.error "$_server_name does not exist. Run augeas.nginx_server first."
        return
        ;;
    esac
  fi
}

function nginx.if.read {
  local _result

  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the server_name exists
  stdlib_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/server/server_name[. = '$_server_name']")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    stdlib_current_state="error"
    return
  fi

  # Check if the location exists
  local _path
  _path="/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']"
  stdlib_current_state=$(augeas.get --lens Nginx --file "$_file" --path "$_path")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  # Check if the key exists and the value matches
  _path="/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']/../${options[key]}[. = '${options[value]}']"
  _result=$(augeas.get --lens Nginx --file "$_file" --path "$_path")
  if [[ "$_result" == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function nginx.if.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../if[0]/#cond '$_cond'")

  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../if[last()]/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding nginx_if $_name with augeas: $_result"
    return
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function nginx.if.update {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']/../${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding nginx_if $_name with augeas: $_result"
    return
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function nginx.if.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']/../${options[key]}")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting nginx_if $_name with augeas: $_result"
    return
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
