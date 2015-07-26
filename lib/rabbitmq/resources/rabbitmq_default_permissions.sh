# == Name
#
# rabbitmq.default_permissions
#
# === Description
#
# Manages default_permissions settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * conf: The conf permission. Required.
# * read: The read permission. Required.
# * write: The write permission. Required.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.default_permissions --conf ".*" --read ".*" --write ".*"
# ```
#
function rabbitmq.default_permissions {
  stdlib.subtitle "rabbitmq.default_permissions"

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
  stdlib.options.create_option conf  "__required__"
  stdlib.options.create_option read  "__required__"
  stdlib.options.create_option write "__required__"
  stdlib.options.create_option file  "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="rabbitmq.default_permissions"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.default_permissions" "$_name"
}

function rabbitmq.default_permissions.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the conf permission exists
  stdlib_current_state=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/default_permissions/value[1][. = '${options[conf]}']")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  # Check if the read permission exists
  stdlib_current_state=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/default_permissions/value[2][. = '${options[read]}']")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  # Check if the write permission exists
  stdlib_current_state=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/default_permissions/value[3][. = '${options[write]}']")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.default_permissions.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/rabbit/default_permissions/value[1] '${options[conf]}'")
  _augeas_commands+=("set /files$_file/rabbit/default_permissions/value[2] '${options[read]}'")
  _augeas_commands+=("set /files$_file/rabbit/default_permissions/value[3] '${options[write]}'")

  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.default_permissions.update {
  rabbitmq.default_permissions.delete
  rabbitmq.default_permissions.create
}

function rabbitmq.default_permissions.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/default_permissions/value[1]")
  _augeas_commands+=("rm /files$_file/rabbit/default_permissions/value[2]")
  _augeas_commands+=("rm /files$_file/rabbit/default_permissions/value[3]")

  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.default_permissions $_name with augeas: $_result"
    return
  fi
}
