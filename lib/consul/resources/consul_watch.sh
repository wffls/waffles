# == Name
#
# consul.watch
#
# === Description
#
# Manages a consul.watch.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the watch. Required. namevar.
# * type: The type of watch: key, keyprefix, services, nodes, service, checks, event. Required.
# * key: A key to monitor when using type "key". Optional.
# * prefix: A prefix to monitor when using type "keyprefix". Optional.
# * service: A service to monitor when using type "service" or "checks". Optional.
# * tag: A service tag to monitor when using type "service". Optional.
# * passingonly: Only return instances passing all health checks when using type "service". Optional.
# * check_state: A state to filter on when using type "checks". Optional.
# * event_name: An event to filter on when using type "event. Optional.
# * datacenter: Can be provided to override the agent's default datacenter. Optional.
# * token: Can be provided to override the agent's default ACL token. Optional.
# * handler: The handler to invoke when the data view updates. Required.
# * file: The file to store the watch in. Required. Defaults to /etc/consul/agent/conf.d/watch-name.json
#
# === Example
#
# ```shell
# consul.watch --name nodes \
#              --type nodes \
#              --handler "/usr/local/bin/build_hosts_file.sh"
# ```
#
function consul.watch {
  stdlib.subtitle "consul.watch"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  if ! stdlib.command_exists consul ; then
    stdlib.error "Cannot find consul"
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state      "present"
  stdlib.options.create_option name       "__required__"
  stdlib.options.create_option type       "__required__"
  stdlib.options.create_option handler    "__required__"
  stdlib.options.create_option token
  stdlib.options.create_option datacenter
  stdlib.options.create_option key
  stdlib.options.create_option prefix
  stdlib.options.create_option service
  stdlib.options.create_option tag
  stdlib.options.create_option passingonly
  stdlib.options.create_option check_state
  stdlib.options.create_option event_name
  stdlib.options.create_option file
  stdlib.options.parse_options "$@"

  # Local Variables
  local _file
  local _name="${options[name]}"
  local _dir=$(dirname "${options[file]}")
  local _simple_options=(type handler token datacenter key prefix service tag passingonly)

  # Internal Resource configuration
  if [[ -z ${options[file]} ]]; then
    _file="/etc/consul/agent/conf.d/watch-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  # Process the resource
  stdlib.resource.process "consul.watch" "$_name"
}

function consul.watch.read {
  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if simple options exist and match
  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'watches']/array/dict/entry[. = '$_o']/*[. = '${options[$_o]}']")
      if [[ $_result == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
    fi
  done

  # check_state conflicts with "state" option, so we need to make a special check here
  if [[ -n ${options[check_state]} ]]; then
    _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'watches']/array/dict/entry[. = 'state']/*[. = '${options[check_state]}']")
    if [[ $_result == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  fi

  # event_name conflicts with "name" option, so we need to make a special check here
  if [[ -n ${options[event_name]} ]]; then
    _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'watches']/array/dict/entry[. = 'name']/*[. = '${options[event_name]}']")
    if [[ $_result == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  fi

  if [[ $stdlib_current_state == "update" ]]; then
    return
  else
    stdlib_current_state="present"
  fi
}

function consul.watch.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  if [[ ! -f $_file ]]; then
    stdlib.debug "Creating empty JSON file."
    stdlib.mute "echo '{}' > $_file"
    _augeas_commands+=("rm /files/${_file}/dict")
  fi

  # Create the check entry
  _augeas_commands+=("set /files/${_file}/dict/entry 'watches'")
  _augeas_commands+=("touch /files/${_file}/dict/entry[. = 'watches']/array")

  # Create the simple options
  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'watches']/array/dict/entry[. = '$_o'] '$_o'")
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'watches']/array/dict/entry[. = '$_o']/string '${options[$_o]}'")
    fi
  done

  if [[ -n ${options[check_state]} ]]; then
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'watches']/array/dict/entry[. = 'state'] 'state'")
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'watches']/array/dict/entry[. = 'state']/string '${options[check_state]}'")
  fi

  if [[ -n ${options[event_name]} ]]; then
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'watches']/array/dict/entry[. = 'name'] 'name'")
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'watches']/array/dict/entry[. = 'name']/string '${options[event_name]}'")
  fi

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function consul.watch.update {
  consul.watch.delete
  consul.watch.create
}

function consul.watch.delete {
  local _result
  local -a _augeas_commands=()

  _augeas_commands+=("rm /files/${_file}/dict")

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}
