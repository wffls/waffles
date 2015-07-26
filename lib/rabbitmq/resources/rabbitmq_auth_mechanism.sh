# == Name
#
# rabbitmq.auth_mechanism
#
# === Description
#
# Manages auth_mechanism settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * mechanism: The auth mechanism. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.auth_mechanism --mechanism PLAIN
# ```
#
function rabbitmq.auth_mechanism {
  stdlib.subtitle "rabbitmq.auth_mechanism"

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
  stdlib.options.create_option state     "present"
  stdlib.options.create_option mechanism "__required__"
  stdlib.options.create_option file      "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[mechanism]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.auth_mechanism" "$_name"
}

function rabbitmq.auth_mechanism.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.list_value_read $_file "auth_mechanisms" "${options[mechanism]}"
}

function rabbitmq.auth_mechanism.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.list_value_create $_file "auth_mechanisms" "${options[mechanism]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.auth_mechanism.update {
  rabbitmq.auth_mechanism.delete
  rabbitmq.auth_mechanism.create
}

function rabbitmq.auth_mechanism.delete {
  rabbitmq.list_value_delete $_file "auth_mechanisms" "${options[mechanism]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.auth_mechanism $_name with augeas: $_result"
    return
  fi
}
