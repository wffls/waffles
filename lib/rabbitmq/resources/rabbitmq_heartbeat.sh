# == Name
#
# rabbitmq.heartbeat
#
# === Description
#
# Manages heartbeat settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * value: The default value. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.heartbeat --value /
# ```
#
function rabbitmq.heartbeat {
  stdlib.subtitle "rabbitmq.heartbeat"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state "present"
  stdlib.options.create_option value "__required__"
  stdlib.options.create_option file  "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  local _name="${options[value]}"
  stdlib.catalog.add "rabbitmq.heartbeat/$_name"

  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  rabbitmq.heartbeat.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      rabbitmq.heartbeat.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        rabbitmq.heartbeat.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        rabbitmq.heartbeat.delete
        rabbitmq.heartbeat.create
        ;;
    esac
  fi
}

function rabbitmq.heartbeat.read {
  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.generic_value_read "$_file" "heartbeat" "${options[value]}"
}

function rabbitmq.heartbeat.create {
  local _result

  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  rabbitmq.generic_value_create "$_file" "heartbeat" "${options[value]}"

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function rabbitmq.heartbeat.delete {
  local _result

  rabbitmq.generic_value_delete "$_file" "heartbeat" "${options[value]}"

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.heartbeat $_name with augeas: $_result"
  fi
}
