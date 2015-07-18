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
# augeas.json_array --file /root/web.json --path / --key foo --value "1 2 3 4"
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

  local -A options
  local -a value
  stdlib.options.create_option state    "present"
  stdlib.options.create_option path
  stdlib.options.create_option key
  stdlib.options.create_mv_option value
  stdlib.options.create_option file     "__required__"
  stdlib.options.parse_options "$@"

  local _path=$(echo "${options[file]}/${options[path]}/" | sed -e 's@/\+@/@g')

  local _name="${_path}${options[key]}"
  stdlib.catalog.add "augeas.json_array/$_name"

  augeas.json_array.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      augeas.json_array.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        augeas.json_array.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        augeas.json_array.create
        ;;
    esac
  fi
}

function augeas.json_array.read {
  local _result

  if [[ ! -f "${options[file]}" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the path exists
  stdlib_current_state=$(augeas.get --lens Json --file "${options[file]}" --path "${options[path]}")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  # Check if the key matches
  _result=$(augeas.get --lens Json --file "${options[file]}" --path "${options[path]}/dict/entry[. = '${options[key]}']")
  if [[ "$_result" == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  # Check if the values match and are in correct position
  local _idx=0
  local _i
  for _i in "${value[@]}"; do
    (( _idx++ ))
    _result=$(augeas.get --lens Json --file "${options[file]}" --path "${options[path]}/dict/entry[. = '${options[key]}']/array/*[$_idx][. = '$_i']")
    if [[ "$_result" == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  done

  stdlib_current_state="present"
}

function augeas.json_array.create {
  local -a _augeas_commands=()
  if [[ ! -f "${options[file]}" ]]; then
    stdlib.debug "Creating empty JSON file."
    stdlib.mute "echo '{}' > ${options[file]}"
    _augeas_commands+=("rm /files${options[file]}/dict")
  fi

  _augeas_commands+=("set /files${_path}dict/entry[. = '${options[key]}'] '${options[key]}'")
  _augeas_commands+=("touch /files${_path}dict/entry[. = '${options[key]}']/array")

  local _idx=0
  local _i
  local _type
  for _i in "${value[@]}"; do
    (( _idx++ ))
    if [[ "$_i" =~ ^-?[0-9]+$ ]]; then
      _type="number"
    elif [[ "$_i" == "true" || "$_i" == "false" ]]; then
      _type="const"
    else
      _type="string"
    fi
    _augeas_commands+=("set /files${_path}dict/entry[. = '${options[key]}']/array/${_type}[$_idx] '$_i'")
  done

  local _result=$(augeas.run --lens Json --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding json ${options[name]} with augeas: $_result"
    return
  fi
}

function augeas.json.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${_path}dict/entry[. = '${options[key]}'")
  local _result=$(augeas.run --lens Json --file ${options[file]} "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting json ${options[name]} with augeas: $_result"
    return
  fi
}
