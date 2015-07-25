# == Name
#
# rabbitmq.hipe_compile
#
# === Description
#
# Manages hipe_compile settings in a rabbitmq.config file.
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
# rabbitmq.hipe_compile --value /
# ```
#
function rabbitmq.hipe_compile {
  stdlib.subtitle "rabbitmq.hipe_compile"

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
  stdlib.options.create_option value "__required__"
  stdlib.options.create_option file  "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[value]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.hipe_compile" "$_name"
}

function rabbitmq.hipe_compile.read {
  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.generic_value_read $_file "hipe_compile" "${options[value]}"
}

function rabbitmq.hipe_compile.create {
  local _result

  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.generic_value_create $_file "hipe_compile" "${options[value]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function rabbitmq.hipe_compile.update {
  rabbitmq.hipe_compile.delete
  rabbitmq.hipe_compile.create
}

function rabbitmq.hipe_compile.delete {
  local _result

  rabbitmq.generic_value_delete $_file "hipe_compile" "${options[value]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.hipe_compile $_name with augeas: $_result"
  fi
}
