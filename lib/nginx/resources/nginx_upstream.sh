# == Name
#
# nginx.upstream
#
# === Description
#
# Manages entries in an nginx upstream block
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the upstream definition. Required. namevar.
# * key: The key. Required.
# * value: A value for the key. Required.
# * options: Extra options for the value. Optional.
# * file: The file to store the settings in. Optional. Defaults to /etc/nginx/conf.d/upstream_name.
#
# === Example
#
# ```shell
# nginx.upstream --name example_com --key server --value server1.example.com --options "weight=5"
# nginx.upstream --name example_com --key server --value server2.example.com
# ```
#
# === Notes
#
# This is broke at the moment due to an issue with the Nginx Augeas lens.
# This comment will be removed when it's working.
#
function nginx.upstream {
  stdlib.subtitle "nginx.upstream"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option name    "__required__"
  stdlib.options.create_option key     "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.create_option options
  stdlib.options.create_option file
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[name]}.${options[key]}.${options[value]}"
  local _dir="/etc/nginx/conf.d"
  local _value _file

  # Internal Resource configuration
  if [[ -n ${options[file]} ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/map_${options[name]}"
  fi

  if [[ -n ${options[options]} ]]; then
    _value="${options[value]} ${options[options]}"
  else
    _value="${options[value]}"
  fi

  # Process the resource
  stdlib.resource.process "nginx.upstream" "$_name"
}

function nginx.upstream.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the server_name exists
  stdlib_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/upstream/#name[. = '${options[name]}']")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  # Check if the key exists and the value matches
  _result=$(augeas.get --lens Nginx --file "$_file" --path "/upstream/#name[. = '${options[name]}']/../${options[key]}[. = '$_value']")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
  fi

  stdlib_current_state="present"
}

function nginx.upstream.create {
  stdlib.capture_error mkdir -p "$_dir"

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/upstream/#name '${options[name]}'")
  _augeas_commands+=("set /files$_file/upstream/#name[. = '${options[name]}']/../${options[key]}[0] '$_value'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding nginx.upstream $_name with augeas: $_result"
    return
  fi
}

function nginx.upstream.update {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/upstream/#name[. = '${options[name]}']/../${options[key]}[0] '$_value'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding nginx.upstream $_name with augeas: $_result"
    return
  fi
}

function nginx.upstream.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/upstream/#name[. = '${options[name]}']/../${options[key]}[. = '$_value'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting nginx.upstream $_name with augeas: $_result"
    return
  fi
}
