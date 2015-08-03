# == Name
#
# augeas.json_array
#
# === Description
#
# Manages a dictionary entry in a JSON file
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * path: The path to the setting in the json tree for non-k/v settings.
# * key: The key of the dictionary that will hold the array.
# * value: The value of the array. Multi-var.
# * file: The file to add the variable to. Required.
#
# === Example
#
# ```shell
# augeas.json_array --file /root/web.json --path / --key foo --value 1 --value 2 --value 3
#
# {"foo":[1,2,3]}
# ```
#
function augeas.json_array {
  stdlib.subtitle "augeas.json_array"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  local -a value
  stdlib.options.create_option state    "present"
  stdlib.options.create_option file     "__required__"
  stdlib.options.create_option path
  stdlib.options.create_option key
  stdlib.options.create_mv_option value
  stdlib.options.parse_options "$@"

  # Local Variables
  local _path="${options[path]}"
  local _name=$(echo "${options[file]}/${_path}/${options[key]}" | sed -e 's@/\+@/@g')

  # Process the resource
  stdlib.resource.process "augeas.json_array" "$_name"
}

function augeas.json_array.read {
  local _result _p _key _key_path _last_path

  if [[ ! -f ${options[file]} ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the path exists
  stdlib_current_state=$(augeas.get --lens Json --file "${options[file]}" --path "${options[path]}")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  stdlib.split "$_path" "/"
  for _key in "${__split[@]}"; do
    if [[ -n $_key ]]; then
      _key_path="/dict/entry[. = '$_key']"
      if [[ -z $_last_path ]]; then
        _last_path="$_key_path"
      else
        _last_path="$_last_path/$_key_path"
      fi

      # Check if the path exists
      stdlib_current_state=$(augeas.get --lens Json --file "${options[file]}" --path "$_last_path")
      if [[ $stdlib_current_state == "absent" ]]; then
        return
      fi
    fi
  done

  # Check if the key matches
  _p=$(echo "$_last_path/dict/entry[. = '${options[key]}']" | sed -e 's@/\+@/@g')
  _result=$(augeas.get --lens Json --file "${options[file]}" --path "$_p")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  # Check if the values match and are in correct position
  local _idx=0
  local _i
  for _i in "${value[@]}"; do
    (( _idx++ ))
    _result=$(augeas.get --lens Json --file "${options[file]}" --path "$_p/array/*[$_idx][. = '$_i']")
    if [[ $_result == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  done

  stdlib_current_state="present"
}

function augeas.json_array.create {
  local -a _augeas_commands=()
  local _p _key _key_path _last_path

  if [[ ! -f "${options[file]}" ]]; then
    stdlib.debug "Creating empty JSON file."
    stdlib.mute "echo '{}' > ${options[file]}"
    _augeas_commands+=("rm /files${options[file]}/dict")
  fi

  # Ensure the path leading up exists
  stdlib.split "$_path" "/"
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

  _p=$(echo "/files/${options[file]}/$_last_path/dict/entry[. = '${options[key]}']/array" | sed -e 's@/\+@/@g')
  _augeas_commands+=("touch $_p")

  local _idx=0
  local _i
  local _type
  for _i in "${value[@]}"; do
    (( _idx++ ))
    if [[ $_i =~ ^-?[0-9]+$ ]]; then
      _type="number"
    elif [[ $_i == "true" || $_i == "false" ]]; then
      _type="const"
    else
      _type="string"
    fi
    _p=$(echo "/files/${options[file]}/$_last_path/dict/entry[. = '${options[key]}']/array/${_type}[$_idx]" | sed -e 's@/\+@/@g')
    _augeas_commands+=("set $_p '$_i'")
  done

  local _result=$(augeas.run --lens Json --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding json ${options[name]} with augeas: $_result"
    return
  fi
}

function augeas.json_array.update {
  augeas.json_array.create
}

function augeas.json_array.delete {
  local -a _augeas_commands=()
  local _p _key _key_path _last_path

  # Lazily build the last path
  stdlib.split "$_path" "/"
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
    stdlib.error "Error deleting json ${options[name]} with augeas: $_result"
    return
  fi
}
