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
  waffles.subtitle "apache.setting"

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
  local -a path
  waffles.options.create_option state   "present"
  waffles.options.create_option key     "__required__"
  waffles.options.create_option value   "__required__"
  waffles.options.create_option file    "/etc/apache2/apache2.conf"
  waffles.options.create_mv_option path
  waffles.options.parse_options "$@"

  # Local Variables
  local _path
  local _parent_path
  local -a _parent_paths
  local _file="${options[file]}"
  local _name="$_file"

  # Internal Resource Configuration
  if [[ $(array.length path) -gt 0 ]]; then
    for p in "${path[@]}"; do
      string.split "$p" "="
      _parent_paths+=("${__split[0]}/arg[. = '${__split[1]}']")
      _name="${_name}.${p}"
    done
    _parent_path=$(array.join "_parent_paths" "/../")
    _path="${_parent_path}/.."
  fi

  _name="${_name}.${options[key]}"
  _values=(${options[value]})

  # Process the resource
  waffles.resource.process "apache.setting" "$_name"
}

function apache.setting.read {
  local _result

  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the parent key/value exists
  if [[ -n $_path ]]; then
    _result=$(augeas.get --lens Httpd --file "$_file" --path "$_parent_path")
    if [[ $_result == "absent" ]]; then
      log.error "$_name state: parent does not exist yet. Please create it first."
      waffles_resource_current_state="error"
      return
    fi
  fi

  # Check if the key exists
  waffles_resource_current_state=$(augeas.get --lens Httpd --file "$_file" --path "$_path/directive[. = '${options[key]}']")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if the value exists
  for v in "${_values[@]}"; do
    _result=$(augeas.get --lens Httpd --file "$_file" --path "$_path/directive[. = '${options[key]}']/arg[. = '$v']")
    if [[ $_result == "absent" ]]; then
      waffles_resource_current_state="update"
      return
    fi
  done

  waffles_resource_current_state="present"
}

function apache.setting.create {
  local _dir=$(dirname "$_file")
  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/$_path/directive[0] '${options[key]}'")
  for v in "${_values[@]}"; do
    _augeas_commands+=("set /files$_file/$_path/directive[. = '${options[key]}']/arg[last()+1] '$v'")
  done

  local _result=$(augeas.run --lens Httpd --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding apache.setting $_name with augeas: $_result"
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
    log.error "Error adding apache.setting $_name with augeas: $_result"
    return
  fi
}

function apache.setting.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/$_path/directive[. = '${options[key]}']")

  local _result=$(augeas.run --lens Httpd --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting apache.setting $_name with augeas: $_result"
    return
  fi
}
