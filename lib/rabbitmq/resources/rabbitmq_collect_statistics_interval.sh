# == Name
#
# rabbitmq.collect_statistics_interval
#
# === Description
#
# Manages collect_statistics_interval settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * interval: The default interval. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.collect_statistics_interval --interval /
# ```
#
function rabbitmq.collect_statistics_interval {
  stdlib.subtitle "rabbitmq.collect_statistics_interval"

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
  stdlib.options.create_option interval "__required__"
  stdlib.options.create_option file  "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[interval]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.collect_statistics_interval" "$_name"
}

function rabbitmq.collect_statistics_interval.read {
  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.generic_value_read $_file "collect_statistics_interval" "${options[interval]}"
}

function rabbitmq.collect_statistics_interval.create {
  local _result

  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.generic_value_create $_file "collect_statistics_interval" "${options[interval]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function rabbitmq.collect_statistics_interval.update {
  rabbitmq.collect_statistics_interval.delete
  rabbitmq.collect_statistics_interval.create
}

function rabbitmq.collect_statistics_interval.delete {
  local _result

  rabbitmq.generic_value_delete $_file "collect_statistics_interval" "${options[interval]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.collect_statistics_interval $_name with augeas: $_result"
  fi
}
