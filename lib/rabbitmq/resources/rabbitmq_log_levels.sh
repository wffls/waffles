# == Name
#
# rabbitmq.log_levels
#
# === Description
#
# Manages log_levels settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * category: The log category. Required. namevar.
# * level: The log level. Optional. Defaults to info
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.log_levels --category connection --level debug
# rabbitmq.log_levels --category channel --level error
# ```
#
function rabbitmq.log_levels {
  stdlib.subtitle "rabbitmq.log_levels"

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
  stdlib.options.create_option state    "present"
  stdlib.options.create_option category "__required__"
  stdlib.options.create_option level    "info"
  stdlib.options.create_option file     "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[category]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.log_levels" "$_name"
}

function rabbitmq.log_levels.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the category exists and the level matches
  stdlib_current_state=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/log_levels/tuple/value[. = '${options[category]}']")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  _result=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/log_levels/tuple/value[. = '${options[category]}']/../value[. = '${options[level]}']")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.log_levels.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/rabbit/log_levels/tuple[0]/value[0] '${options[category]}'")
  _augeas_commands+=("set /files$_file/rabbit/log_levels/tuple/value[. = '${options[category]}']/../value[0] '${options[level]}'")

  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.log_levels.update {
  rabbitmq.log_levels.delete
  rabbitmq.log_levels.create
}

function rabbitmq.log_levels.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/log_levels/tuple/value[. = '${options[category]}']/..")
  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.log_levels $_name with augeas: $_result"
    return
  fi
}
