# == Name
#
# nginx.http
#
# === Description
#
# Manages http key/value settings in nginx.conf
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
# nginx.http --key index --value "index.html index.htm index.php"
# log_format='main "$remote_addr - $remote_user [$time_local] $status \"$request\" $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\""'
# nginx.http --key log_format --value "$log_format"
# nginx.http --key access_log --value "/var/log/nginx/access.log main"
# ```
#
function nginx.http {
  waffles.subtitle "nginx.http"

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
  local  _file

  # Internal Resource Configuration
  if [[ -n ${options[file]} ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/nginx.conf"
  fi

  # Process the resource
  waffles.resource.process "nginx.http" "$_name"
}

function nginx.http.read {
  local _result

  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the key exists and the value matches
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/http/${options[key]}")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # If something has been escaped, we need to doubly escape it for augeas
  local _value
  if [[ ${options[value]} =~ '\"' ]]; then
    _value=$(echo "${options[value]}" | sed -e 's/\"/\\"/g')
  else
    _value="${options[value]}"
  fi

  _result=$(augeas.get --lens Nginx --file "$_file" --path "/http/${options[key]}[. = '$_value']")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function nginx.http.create {
  exec.capture_error mkdir -p "$_dir"

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/http/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx.http $_name with augeas: $_result"
    return
  fi
}

function nginx.http.update {
  nginx.http.delete
  nginx.http.create
}

function nginx.http.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/http/${options[key]}[. = '${options[value]}']")
  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting nginx.http $_name with augeas: $_result"
    return
  fi
}
