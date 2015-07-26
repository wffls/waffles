# == Name
#
# rabbitmq.default_user
#
# === Description
#
# Manages default_user settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The default user. Required. namevar.
# * pass: The default password. Required. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.default_user --user guest --pass guest
# ```
#
function rabbitmq.default_user {
  stdlib.subtitle "rabbitmq.default_user"

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
  stdlib.options.create_option user "__required__"
  stdlib.options.create_option pass "__required__"
  stdlib.options.create_option file  "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[user]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.default_user" "$_name"
}

function rabbitmq.default_user.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmq.generic_value_read $_file "default_user" "${options[user]}"
  if [[ $stdlib_current_state != "present" ]]; then
    return
  fi

  rabbitmq.generic_value_read $_file "default_pass" "${options[pass]}"
}

function rabbitmq.default_user.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  rabbitmq.generic_value_create $_file "default_user" "${options[user]}"
  rabbitmq.generic_value_create $_file "default_pass" "${options[pass]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.default_user.update {
  rabbitmq.default_user.delete
  rabbitmq.default_user.create
}

function rabbitmq.default_user.delete {
  rabbitmq.generic_value_delete $_file "default_user" "${options[user]}"
  rabbitmq.generic_value_delete $_file "default_pass" "${options[pass]}"

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.default_user $_name with augeas: $_result"
    return
  fi
}
