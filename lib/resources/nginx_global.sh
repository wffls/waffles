# == Name
#
# nginx.global
#
# === Description
#
# Manages global key/value settings in nginx.conf
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * key: The key. Required.
# * value: A value for the key. Required.
# * file: The file to store the settings in. Optional. Defaults to /etc/nginx/nginx.conf.
#
# === Example
#
# ```shell
# nginx.global --key user --value www-data
# nginx.global --key worker_processes --value 4
# ```
#
function nginx.global {
  waffles.subtitle "nginx.global"

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
  waffles.options.create_option state "present"
  waffles.options.create_option key   "__required__"
  waffles.options.create_option value "__required__"
  waffles.options.create_option file
  waffles.options.parse_options "$@"

  # Local Variables
  local _name="${options[key]}"
  local _dir="/etc/nginx/"
  local _server_name _file

  # Internal Resource configuration
  if [[ -n ${options[file]} ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/nginx.conf"
  fi

  # Process the resource
  waffles.resource.process "nginx.global" "$_name"
}

function nginx.global.read {
  local _result

  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the key exists and the value matches
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/${options[key]}")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  _result=$(augeas.get --lens Nginx --file "$_file" --path "/${options[key]}[. = '${options[value]}']")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function nginx.global.create {
  exec.capture_error mkdir -p "$_dir"

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx.http $_name with augeas: $_result"
    return
  fi
}

function nginx.global.update {
  nginx.global.delete
  nginx.global.create
}

function nginx.global.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/${options[key]}[. = '${options[value]}']")
  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting nginx.global $_name with augeas: $_result"
    return
  fi
}
