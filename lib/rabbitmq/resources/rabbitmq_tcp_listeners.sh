# == Name
#
# rabbitmq.tcp_listeners
#
# === Description
#
# Manages tcp_listeners settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * address: The address to listen on. Required. namevar.
# * port: The port to listen on. Optional. Defaults to 5672.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.tcp_listeners --address 127.0.0.1 --port 5672
# rabbitmq.tcp_listeners --address ::1 --port 5672
# ```
#
function rabbitmq.tcp_listeners {
  stdlib.subtitle "rabbitmq.tcp_listeners"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option address "__required__"
  stdlib.options.create_option port    "5672"
  stdlib.options.create_option file    "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[address]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.tcp_listeners" "$_name"
}

function rabbitmq.tcp_listeners.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the address exists and the port matches
  stdlib_current_state=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/tcp_listeners/tuple/value[. = '${options[address]}']")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  _result=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/tcp_listeners/tuple/value[. = '${options[address]}']/../value[. = '${options[port]}']")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.tcp_listeners.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/rabbit/tcp_listeners/tuple[0]/value[0] '${options[address]}'")
  _augeas_commands+=("set /files$_file/rabbit/tcp_listeners/tuple/value[. = '${options[address]}']/../value[0] '${options[port]}'")

  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.tcp_listeners.update {
  rabbitmq.tcp_listeners.delete
  rabbitmq.tcp_listeners.create
}

function rabbitmq.tcp_listeners.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/tcp_listeners/tuple/value[. = '${options[address]}']/..")
  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.tcp_listeners $_name with augeas: $_result"
    return
  fi
}
