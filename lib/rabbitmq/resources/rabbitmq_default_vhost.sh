# == Name
#
# rabbitmq.default_vhost
#
# === Description
#
# Manages default_vhost settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * vhost: The default vhost. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.default_vhost --vhost /
# ```
#
function rabbitmq.default_vhost {
  stdlib.subtitle "rabbitmq.default_vhost"

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
  stdlib.options.create_option state "present"
  stdlib.options.create_option vhost "__required__"
  stdlib.options.create_option file  "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[vhost]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.default_vhost" "$_name"
}

function rabbitmq.default_vhost.read {
  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.generic_value_read $_file "default_vhost" "${options[vhost]}"
}

function rabbitmq.default_vhost.create {
  local _result

  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.generic_value_create $_file "default_vhost" "${options[vhost]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function rabbitmq.default_vhost.update {
  rabbitmq.default_vhost.delete
  rabbitmq.default_vhost.create
}

function rabbitmq.default_vhost.delete {
  local _result

  rabbitmq.generic_value_delete $_file "default_vhost" "${options[vhost]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.default_vhost $_name with augeas: $_result"
  fi
}
