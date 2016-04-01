# == Name
#
# nginx.server
#
# === Description
#
# Manages key/value settings in an nginx server block
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the server. Required. namevar.
# * server_name: The domain of the server. Optional. Defaults to name.
# * key: The key. Required.
# * value: A value for the key. Required.
# * file: The file to store the settings in. Optional. Defaults to /etc/nginx/sites-enabled/name.
#
# === Example
#
# ```shell
# nginx.server --name example.com --key root --value /var/www/html
# nginx.server --name example.com --key listen --value 80
# nginx.server --name example.com --key index --value index.php
# ```
#
function nginx.server {
  waffles.subtitle "nginx.server"

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
  waffles.options.create_option key         "__required__"
  waffles.options.create_option value       "__required__"
  waffles.options.create_option file
  waffles.options.create_option server_name
  waffles.options.parse_options "$@"

  # Local Variables
  local _name="${options[name]}.${options[key]}"
  local _dir="/etc/nginx/sites-enabled"
  local _server_name _file

  # Internal Resource Configuration
  if [[ -n ${options[server_name]} ]]; then
    _server_name="${options[server_name]}"
  else
    _server_name="${options[name]}"
  fi

  if [[ -n ${options[file]} ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/${options[name]}"
  fi

  # Process the resource
  waffles.resource.process "nginx.server" "$_name"
}

function nginx.server.read {
  local _result

  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the server_name exists
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/server/server_name[. = '$_server_name']")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if the key exists and the value matches
  _result=$(augeas.get --lens Nginx --file "$_file" --path "/server/server_name[. = '$_server_name']/../${options[key]}[. = '${options[value]}']")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
  fi
}

function nginx.server.create {
  exec.capture_error mkdir -p "$_dir"

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/server/server_name '$_server_name'")
  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx_server $_name with augeas: $_result"
    return
  fi
}

function nginx.server.update {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx_server $_name with augeas: $_result"
    return
  fi
}

function nginx.server.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/server/server_name[. = '$_server_name']/../${options[key]}")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting nginx_server $_name with augeas: $_result"
    return
  fi
}
