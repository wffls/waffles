# == Name
#
# augeas.json_dict
#
# === Description
#
# Manages a dictionary entry in a JSON file
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * path: The path to the setting in the json tree for non-k/v settings.
# * key: The key portion of the dictionary. Required.
# * value: The value portion of the dictionary. Required.
# * type: The type of the value. Optional.
# * file: The file to add the variable to. Required.
#
# === Example
#
# ```shell
# augeas.json_dict --file /root/web.json --path / --key "foo" --value _dict
# augeas.json_dict --file /root/web.json --path / --key "foo" --value _array
# augeas.json_dict --file /root/web.json --path / --key "foo" --value "bar"
# ```
#
function augeas.json_dict {
  waffles.subtitle "augeas.json_dict"

  if ! waffles.command_exists augtool ; then
    log.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state "present"
  waffles.options.create_option path
  waffles.options.create_option key   "__required__"
  waffles.options.create_option value "__required__"
  waffles.options.create_option type
  waffles.options.create_option file  "__required__"
  waffles.options.parse_options "$@"

  # Local Variables
  local _path="${options[path]}"
  local _name=$(echo "${options[file]}/${_path}/${options[key]}" | sed -e 's@/\+@/@g')

  # Internal Resource Configuration
  # Determine the type of the value
  local _type
  if [[ -n ${options[type]} ]]; then
    _type="${options[type]}"
  elif [[ ${options[value]} =~ ^-?[0-9]+$ ]]; then
    _type="number"
  elif [[ ${options[value]} == "true" || ${options[value]} == "false" ]]; then
    _type="const"
  else
    _type="string"
  fi

  # Process the resource
  waffles.resource.process "augeas.json_dict" "$_name"
}

function augeas.json_dict.read {
  local _result _p _key _key_path _last_path

  if [[ ! -f ${options[file]} ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Ensure the path leading up exists
  string.split "$_path" "/"
  for _key in "${__split[@]}"; do
    if [[ -n $_key ]]; then
      _key_path="/dict/entry[. = '$_key']"
      if [[ -z $_last_path ]]; then
        _last_path="$_key_path"
      else
        _last_path="$_last_path/$_key_path"
      fi

      # Check if the path exists
      waffles_resource_current_state=$(augeas.get --lens Json --file "${options[file]}" --path "$_last_path")
      if [[ $waffles_resource_current_state == "absent" ]]; then
        return
      fi
    fi
  done

  # Check if the key matches
  _p=$(echo "$_last_path/dict/entry[. = '${options[key]}']" | sed -e 's@/\+@/@g')
  _result=$(augeas.get --lens Json --file "${options[file]}" --path "$_p")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  # Check if the value matches
  case "${options[value]}" in
    _dict)
      _p=$(echo "$_last_path/dict/entry[. = '${options[key]}']/dict" | sed -e 's@/\+@/@g')
      _result=$(augeas.get --lens Json --file "${options[file]}" --path "$_p")
      ;;
    _array)
      _p=$(echo "$_last_path/dict/entry[. = '${options[key]}']/array" | sed -e 's@/\+@/@g')
      _result=$(augeas.get --lens Json --file "${options[file]}" --path "$_p")
      ;;
    *)
      _p=$(echo "$_last_path/dict/entry[. = '${options[key]}']/${_type}" | sed -e 's@/\+@/@g')
      _result=$(augeas.get --lens Json --file "${options[file]}" --path "$_p[. = '${options[value]}']")
      ;;
  esac

  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function augeas.json_dict.create {
  local -a _augeas_commands=()
  local _p _key _key_path _last_path

  if [[ ! -f ${options[file]} ]]; then
    log.debug "Creating empty JSON file."
    exec.mute "echo '{}' > ${options[file]}"
    _augeas_commands+=("rm /files${options[file]}/dict")
  fi

  # Ensure the path leading up exists
  string.split "$_path" "/"
  for _key in "${__split[@]}"; do
    if [[ -n $_key ]]; then
      _key_path="/dict/entry[. = '$_key']"
      if [[ -z $_last_path ]]; then
        _last_path="$_key_path"
      else
        _last_path="$_last_path/$_key_path"
      fi

      _p=$(echo "/files/${options[file]}/$_last_path" | sed -e 's@/\+@/@g')
      _augeas_commands+=("set $_p '$_key'")

      _p=$(echo "/files/${options[file]}/$_last_path/dict" | sed -e 's@/\+@/@g')
      _augeas_commands+=("touch $_p")
    fi
  done

  _p=$(echo "/files/${options[file]}/$_last_path/dict/entry[. = '${options[key]}']" | sed -e 's@/\+@/@g')
  _augeas_commands+=("set $_p '${options[key]}'")

  case "${options[value]}" in
    _dict)
      _p=$(echo "/files/${options[file]}/$_last_path/dict/entry[. = '${options[key]}']/dict" | sed -e 's@/\+@/@g')
      _augeas_commands+=("touch $_p")
      ;;
    _array)
      _p=$(echo "/files/${options[file]}/$_last_path/dict/entry[. = '${options[key]}']/array" | sed -e 's@/\+@/@g')
      _augeas_commands+=("touch $_p")
      ;;
    *)
      _p=$(echo "/files/${options[file]}/$_last_path/dict/entry[. = '${options[key]}']/$_type" | sed -e 's@/\+@/@g')
      _augeas_commands+=("set $_p '${options[value]}'")
      ;;
  esac

  local _result=$(augeas.run --lens Json --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding json ${options[name]} with augeas: $_result"
    return
  fi
}

function augeas.json_dict.update {
  augeas.json_dict.create
}

function augeas.json_dict.delete {
  local -a _augeas_commands=()
  local _p _key _key_path _last_path

  # Lazily build the last path
  string.split "$_path" "/"
  for _key in "${__split[@]}"; do
    if [[ -n $_key ]]; then
      _key_path="/dict/entry[. = '$_key']"
      if [[ -z $_last_path ]]; then
        _last_path="$_key_path"
      else
        _last_path="$_last_path/$_key_path"
      fi
    fi
  done

  _p=$(echo "/files/${options[file]}/$_last_path/dict/entry[. = '${options[key]}']" | sed -e 's@/\+@/@g')
  _augeas_commands+=("rm $_p")
  local _result=$(augeas.run --lens Json --file ${options[file]} "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting json ${options[name]} with augeas: $_result"
    return
  fi
}
