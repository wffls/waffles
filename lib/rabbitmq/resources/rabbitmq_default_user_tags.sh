# == Name
#
# rabbitmq.default_user_tags
#
# === Description
#
# Manages default_user_tags settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * tag: The auth tag. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.default_user_tags --tag PLAIN
# ```
#
function rabbitmq.default_user_tags {
  stdlib.subtitle "rabbitmq.default_user_tags"

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
  stdlib.options.create_option tag "__required__"
  stdlib.options.create_option file    "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[tag]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.default_user_tags" "$_name"
}

function rabbitmq.default_user_tags.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.list_value_read $_file "default_user_tagss" "${options[tag]}"
}

function rabbitmq.default_user_tags.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.list_value_create $_file "default_user_tagss" "${options[tag]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.default_user_tags.update {
  rabbitmq.default_user_tags.delete
  rabbitmq.default_user_tags.create
}

function rabbitmq.default_user_tags.delete {
  rabbitmq.list_value_create $_file "default_user_tagss" "${options[tag]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.default_user_tags $_name with augeas: $_result"
    return
  fi
}
