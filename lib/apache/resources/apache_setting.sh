# == Name
#
# apache.setting
#
# === Description
#
# Manages key/value settings in an Apache config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * key: The name of the setting. Required. namevar.
# * value: The value of the setting. Required. namevar.
# * path: The path leading up to the key. Optional. Multi. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/apache2/apache2.conf. namevar.
#
# === Example
#
# ```shell
# apache.setting --path "VirtualHost=*:80" \
#                --path "Directory=/" \
#                --key Require --value valid-user \
#                --file /etc/apache2/sites-enabled/000-default.conf
# ```
#
function apache.setting {
  stdlib.subtitle "apache.setting"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  local -a path
  stdlib.options.create_option state   "present"
  stdlib.options.create_option key     "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.create_option file    "/etc/apache2/apache2.conf"
  stdlib.options.create_mv_option path
  stdlib.options.parse_options "$@"

  local _path
  local _parent_path
  local -a _parent_paths
  local _file="${options[file]}"
  local _name="$_file"

  if [[ $(stdlib.array_length path) -gt 0 ]]; then
    for p in "${path[@]}"; do
      stdlib.split "$p" "="
      _parent_paths+=("${__split[0]}/arg[. = '${__split[1]}']")
      _name="${_name}.${p}"
    done
    _parent_path=$(stdlib.array_join "_parent_paths" "/../")
    _path="${_parent_path}/.."
  fi

  _name="${_name}.${options[key]}"
  _values=(${options[value]})

  stdlib.catalog.add "apache.setting/$_name"

  apache.setting.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      apache.setting.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        apache.setting.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        apache.setting.update
        ;;
      error)
        stdlib.error "$_name state: parent does not exist yet. Please create it first."
        return
        ;;
    esac
  fi
}

function apache.setting.read {
  local _result

  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the parent key/value exists
  if [[ -n "$_path" ]]; then
    _result=$(augeas.get --lens Httpd --file "$_file" --path "$_parent_path")
    if [[ $_result == "absent" ]]; then
      stdlib_current_state="error"
      return
    fi
  fi

  # Check if the key exists
  stdlib_current_state=$(augeas.get --lens Httpd --file "$_file" --path "$_path/directive[. = '${options[key]}']")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  # Check if the value exists
  for v in "${_values[@]}"; do
    _result=$(augeas.get --lens Httpd --file "$_file" --path "$_path/directive[. = '${options[key]}']/arg[. = '$v']")
    if [[ $_result == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  done

  stdlib_current_state="present"
}

function apache.setting.create {
  local _dir=$(dirname "$_file")
  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/$_path/directive[0] '${options[key]}'")
  for v in "${_values[@]}"; do
    _augeas_commands+=("set /files$_file/$_path/directive[. = '${options[key]}']/arg[last()+1] '$v'")
  done

  local _result=$(augeas.run --lens Httpd --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding apache.setting $_name with augeas: $_result"
    return
  fi
}

function apache.setting.update {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/$_path/directive[. = '${options[key]}']/*")
  for v in "${_values[@]}"; do
    _augeas_commands+=("set /files$_file/$_path/directive[. = '${options[key]}']/arg[last()+1] '$v'")
  done

  local _result=$(augeas.run --lens Httpd --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding apache.setting $_name with augeas: $_result"
    return
  fi
}

function apache.setting.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/$_path/directive[. = '${options[key]}']")

  local _result=$(augeas.run --lens Httpd --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting apache.setting $_name with augeas: $_result"
    return
  fi
}
