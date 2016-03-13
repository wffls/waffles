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
  waffles.subtitle "nginx.if"

  if ! waffles.command_exists augtool ; then
    log.error "Cannot find augtool."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state       "present"
  waffles.options.create_option name        "__required__"
  waffles.options.create_option server_name "__required__"
  waffles.options.create_option key         "__required__"
  waffles.options.create_option value       "__required__"
  waffles.options.create_option file
  waffles.options.parse_options "$@"

  local _name="${options[name]}.${options[key]}"
  waffles.catalog.add "nginx.if/$_name"

  local _dir="/etc/nginx/sites-enabled"
  local _server_name="${options[server_name]}"
  local _cond="(${options[name]})"
  local _file

  if [[ -n "${options[file]}" ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/${_server_name}"
  fi

  # Process the resource
  waffles.resource.process
  nginx.if.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$waffles_resource_current_state" != "absent" ]]; then
      log.info "$_name state: $waffles_resource_current_state, should be absent."
      nginx.if.delete
    fi
  else
    case "$waffles_resource_current_state" in
      absent)
        log.info "$_name state: absent, should be present."
        nginx.if.create
        ;;
      present)
        log.debug "$_name state: present."
        ;;
      update)
        log.info "$_name state: present, needs updated."
        nginx.if.update
        ;;
      error)
        log.error "$_server_name does not exist. Run augeas.nginx_server first."
        return
        ;;
    esac
  fi
}

function nginx.if.read {
  local _result

  if [[ ! -f "$_file" ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the server_name exists
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/server/server_name[. = '$_server_name']")
  if [[ "$waffles_resource_current_state" == "absent" ]]; then
    waffles_resource_current_state="error"
    return
  fi

  # Check if the location exists
  local _path
  _path="/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']"
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "$_path")
  if [[ "$waffles_resource_current_state" == "absent" ]]; then
    return
  fi

  # Check if the key exists and the value matches
  _path="/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']/../${options[key]}[. = '${options[value]}']"
  _result=$(augeas.get --lens Nginx --file "$_file" --path "$_path")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function nginx.if.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../if[0]/#cond '$_cond'")

  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../if[last()]/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx_if $_name with augeas: $_result"
    return
  fi

  waffles_state_changed="true"
  waffles_resource_changed="true"
  let "waffles_catalog_changes++"
}

function nginx.if.update {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']/../${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx_if $_name with augeas: $_result"
    return
  fi

  waffles_state_changed="true"
  waffles_resource_changed="true"
  let "waffles_catalog_changes++"
}

function nginx.if.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/server/server_name[. = '$_server_name']/../if/#cond[. = '$_cond']/../${options[key]}")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting nginx_if $_name with augeas: $_result"
    return
  fi

  waffles_state_changed="true"
  waffles_resource_changed="true"
  let "waffles_catalog_changes++"
}
