# == Name
#
# rabbitmq.queue_index_max_journal_entries
#
# === Description
#
# Manages queue_index_max_journal_entries settings in a rabbitmq.config file.
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
# rabbitmq.queue_index_max_journal_entries --value /
# ```
#
function rabbitmq.queue_index_max_journal_entries {
  stdlib.subtitle "rabbitmq.queue_index_max_journal_entries"

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
  stdlib.resource.process "rabbitmq.queue_index_max_journal_entries" "$_name"
}

function rabbitmq.queue_index_max_journal_entries.read {
  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.generic_value_read $_file "queue_index_max_journal_entries" "${options[value]}"
}

function rabbitmq.queue_index_max_journal_entries.create {
  local _result

  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.generic_value_create $_file "queue_index_max_journal_entries" "${options[value]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function rabbitmq.queue_index_max_journal_entries.update {
  rabbitmq.queue_index_max_journal_entries.delete
  rabbitmq.queue_index_max_journal_entries.create
}

function rabbitmq.queue_index_max_journal_entries.delete {
  local _result

  rabbitmq.generic_value_delete $_file "queue_index_max_journal_entries" "${options[value]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.queue_index_max_journal_entries $_name with augeas: $_result"
  fi
}
