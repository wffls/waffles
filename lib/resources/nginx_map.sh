# == Name
#
# nginx.map
#
# === Description
#
# Manages entries in an nginx.map block
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the map definition. Required.
# * source: The source of the map definition. Required.
# * variable: The variable of the map definition. Required.
# * key: The key. Required.
# * value: A value for the key. Required.
# * file: The file to store the settings in. Optional. Defaults to /etc/nginx/conf.d/map_name.
#
# === Example
#
# ```shell
# nginx.map --name my_map --source '$http_host' --variable '$name' --key default --value 0
# nginx.map --name my_map --source '$http_host' --variable '$name' --key example.com --value 1
# ```
#
function nginx.map {
  waffles.subtitle "nginx.map"

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
  waffles.options.create_option state    "present"
  waffles.options.create_option name     "__required__"
  waffles.options.create_option source   "__required__"
  waffles.options.create_option variable "__required__"
  waffles.options.create_option key      "__required__"
  waffles.options.create_option value    "__required__"
  waffles.options.create_option file
  waffles.options.parse_options "$@"

  # Local Variables
  local _name="${options[name]}.${options[source]}.${options[key]}"
  local _dir="/etc/nginx/conf.d"
  local _value _file

  # Internal Resource Configuration
  if [[ -n ${options[file]} ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/map_${options[name]}"
  fi

  # Process the resource
  waffles.resource.process "nginx.map" "$_name"
}

function nginx.map.read {
  local _result

  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the server_name exists
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/map/#source[. = '${options[source]}']")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if the variable exists and matches
  _result=$(augeas.get --lens Nginx --file "$_file" --path "/map/#source[. = '${options[source]}']/../#variable[. = '${options[variable]}']")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
  fi

  # Check if the key exists and the value matches
  _result=$(augeas.get --lens Nginx --file "$_file" --path "/map/#source[. = '${options[source]}']/../${options[key]}[. = '${options[value]}']")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
  fi

  waffles_resource_current_state="present"
}

function nginx.map.create {
  exec.capture_error mkdir -p "$_dir"

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/map/#source '${options[source]}'")
  _augeas_commands+=("set /files$_file/map/#source[. = '${options[source]}']/../#variable '${options[variable]}'")
  _augeas_commands+=("set /files$_file/map/#source[. = '${options[source]}']/../${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx.map $_name with augeas: $_result"
    return
  fi
}

function nginx.map.update {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/map/#source[. = '${options[source]}']/../#variable '${options[variable]}'")
  _augeas_commands+=("set /files$_file/map/#source[. = '${options[source]}']/../${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx.map $_name with augeas: $_result"
    return
  fi
}

function nginx.map.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/map/#source[. = '${options[source]}']/../${options[key]}[. = '$_value'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting nginx.map $_name with augeas: $_result"
    return
  fi
}
