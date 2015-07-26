# == Name
#
# rabbitmq.auth_backend
#
# === Description
#
# Manages auth_backend settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * backend: The auth backend. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.auth_backend --backend PLAIN
# ```
#
function rabbitmq.auth_backend {
  stdlib.subtitle "rabbitmq.auth_backend"

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
  stdlib.options.create_option backend "__required__"
  stdlib.options.create_option file    "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[backend]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.auth_backend" "$_name"
}

function rabbitmq.auth_backend.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.list_value_read $_file "auth_backends" "${options[backend]}"
}

function rabbitmq.auth_backend.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.list_value_create $_file "auth_backends" "${options[backend]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.auth_backend.update {
  rabbitmq.auth_backend.delete
  rabbitmq.auth_backend.create
}

function rabbitmq.auth_backend.delete {
  rabbitmq.list_value_create $_file "auth_backends" "${options[backend]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.auth_backend $_name with augeas: $_result"
    return
  fi
}
