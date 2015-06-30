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
  stdlib.subtitle "nginx.http"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state "present"
  stdlib.options.create_option key   "__required__"
  stdlib.options.create_option value "__required__"
  stdlib.options.create_option file
  stdlib.options.parse_options "$@"

  local _name="${options[key]}"
  stdlib.catalog.add "nginx.http/$_name"

  local _dir="/etc/nginx/"
  local  _file

  if [[ -n "${options[file]}" ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/nginx.conf"
  fi

  nginx.http.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      nginx.http.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        nginx.http.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        nginx.http.delete
        nginx.http.create
        ;;
    esac
  fi
}

function nginx.http.read {
  local _result

  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the key exists and the value matches
  stdlib_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/http/${options[key]}")
  if [[ $stdlib_current_state == absent ]]; then
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
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function nginx.http.create {
  stdlib.capture_error mkdir -p "$_dir"

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/http/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding nginx.http $_name with augeas: $_result"
    return
  fi
}

function nginx.http.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/http/${options[key]}[. = '${options[value]}']")
  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting nginx.http $_name with augeas: $_result"
    return
  fi
}
