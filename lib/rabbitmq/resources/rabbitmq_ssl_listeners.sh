# == Name
#
# rabbitmq.ssl_listeners
#
# === Description
#
# Manages ssl_listeners settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * port: The port to listen on. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.ssl_listeners --port 5671
# ```
#
function rabbitmq.ssl_listeners {
  stdlib.subtitle "rabbitmq.ssl_listeners"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option port    "__required__"
  stdlib.options.create_option file    "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  local _name="${options[port]}"
  stdlib.catalog.add "rabbitmq.ssl_listeners/$_name"

  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  rabbitmq.ssl_listeners.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      rabbitmq.ssl_listeners.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        rabbitmq.ssl_listeners.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        rabbitmq.ssl_listeners.delete
        rabbitmq.ssl_listeners.create
        ;;
    esac
  fi
}

function rabbitmq.ssl_listeners.read {
  local _result

  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the port exists and matches
  stdlib_current_state=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/ssl_listeners/value[. = '${options[port]}']")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.ssl_listeners.create {
  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/rabbit/ssl_listeners/value[0] '${options[port]}'")

  local _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.ssl_listeners.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/ssl_listeners/value[. = '${options[port]}']")
  local _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.ssl_listeners $_name with augeas: $_result"
    return
  fi
}
