# == Name
#
# consul.service
#
# === Description
#
# Manages a consul service.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the service. Required. namevar.
# * id: A unique ID for the service. Optional.
# * tag: Tags to describe the service. Optional. Multi-var.
# * address: The address of the service. Optional.
# * port: The port that the service runs on. Optional.
# * token: An ACL token. Optional.
# * check: The script or location for the check. Optional. Multi-var.
# * check_type: The type of check. Optional. Multi-var.
# * check_interval: The interval to run the script. Optional. Multi-var.
# * check_ttl: The TTL of the check. Optional. Multi-var.
# * file: The file to store the service in. Required. Defaults to /etc/consul.d/service-name.json
#
# === Example
#
# ```shell
# consul.service --name mysql \
#                --port 3306 \
#                --check_type "script" \
#                --check "/usr/local/bin/check_mysql.sh" \
#                --check_interval "60s"
# ```
#
function consul.service {
  stdlib.subtitle "consul.service"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  local -a tag
  local -a check
  local -a check_type
  local -a check_interval
  local -a check_ttl
  stdlib.options.create_option    state   "present"
  stdlib.options.create_option    name    "__required__"
  stdlib.options.create_option    id
  stdlib.options.create_option    address
  stdlib.options.create_option    port
  stdlib.options.create_option    token
  stdlib.options.create_mv_option tag
  stdlib.options.create_mv_option check
  stdlib.options.create_mv_option check_type
  stdlib.options.create_mv_option check_interval
  stdlib.options.create_mv_option check_ttl
  stdlib.options.create_option    file
  stdlib.options.parse_options "$@"

  local _name="${options[name]}"
  stdlib.catalog.add "consul.service/${options[name]}"

  local _file
  if [[ -z "${options[file]}" ]]; then
    _file="/etc/consul.d/service-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  local _dir=$(dirname "${options[file]}")

  local _simple_options=(name id address port token)
  local _check_options=(check check_type check_interval check_ttl)

  consul.service.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      consul.service.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        consul.service.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        consul.service.delete
        consul.service.create
        ;;
    esac
  fi
}

function consul.service.read {
  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if simple options exist and match
  for _o in "${_simple_options[@]}"; do
    if [[ -n "${options[$_o]}" ]]; then
      _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'service']/dict/entry[. = '$_o']/*[. = '${options[$_o]}']")
      if [[ "$_result" == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
    fi
  done

  # Check if tags exist
  for _t in "${tag[@]}"; do
    _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'service']/dict/entry[. = 'tags']/array/string[. = '$_t']")
    if [[ "$_result" == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  done

  # Check if checks exist
  _i=0
  for _o in "${check[@]}"; do
    _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict/entry[. = '${check_type[$_i]}']/*[. = '${check[$_i]}']")
    if [[ "$_result" == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi

    if [[ -n "${check_interval[$_i]}" ]]; then
      _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict/entry[. = 'interval']/*[. = '${check_interval[$_i]}']")
      if [[ "$_result" == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
    fi

    if [[ -n "${check_ttl[$_i]}" ]]; then
      _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict/entry[. = 'ttl']/*[. = '${check_ttl[$_i]}']")
      if [[ "$_result" == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
    fi

    (( _i+=1 ))
  done

  if [[ "$stdlib_current_state" == "update" ]]; then
    return
  else
    stdlib_current_state="present"
  fi
}

function consul.service.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  if [[ ! -f "$_file" ]]; then
    stdlib.debug "Creating empty JSON file."
    stdlib.mute "echo '{}' > $_file"
    _augeas_commands+=("rm /files/${_file}/dict")
  fi

  # Create the service entry
  _augeas_commands+=("set /files/${_file}/dict/entry 'service'")
  _augeas_commands+=("touch /files/${_file}/dict/entry[. = 'service']/dict")

  # Create the simple options
  for _o in "${_simple_options[@]}"; do
    if [[ -n "${options[$_o]}" ]]; then
      local _type
      if [[ "$_o" == "port" ]]; then
        _type="number"
      else
        _type="string"
      fi
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = '$_o'] '$_o'")
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = '$_o']/$_type '${options[$_o]}'")
    fi
  done

  for _t in "${tag[@]}"; do
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'tags'] 'tags'")
    _augeas_commands+=("touch /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'tags']/array")
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'tags']/array/string[0] '$_t'")
  done

  # Add checks
  _i=0
  _x=1
  for _o in "${check[@]}"; do
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks'] 'checks'")
    _augeas_commands+=("touch /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks']/array")
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict[$_x]/entry[. = '${check_type[$_i]}'] '${check_type[$_i]}'")
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict[$_x]/entry[. = '${check_type[$_i]}']/string '${check[$_i]}'")

    if [[ -n "${check_interval[$_i]}" ]]; then
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict[$_x]/entry[. = 'interval'] 'interval'")
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict[$_x]/entry[. = 'interval']/string '${check_interval[$_i]}'")
    fi

    if [[ -n "${check_ttl[$_i]}" ]]; then
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict[$_x]/entry[. = 'ttl'] 'ttl'")
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'service']/dict/entry[. = 'checks']/array/dict[$_x]/entry[. = 'ttl']/string '${check_ttl[$_i]}'")
    fi

    (( _i+=1 ))
    (( _x+=1 ))
  done

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function consul.service.delete {
  local _result
  local -a _augeas_commands=()

  _augeas_commands+=("rm /files/${_file}/dict/entry[. = 'service']")

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
