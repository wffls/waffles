# == Name
#
# rabbitmq.ssl_options
#
# === Description
#
# Manages ssl_options settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * keyfile: The certificate key. Required.
# * certfile: The certificate. Required.
# * cacertfile: The ca cert. Optional.
# * verify: Verify the peer certificate. Optional.
# * fail_if_no_peer_cert: Fail if no peer cert. Optional.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.ssl_options --certfile /path/to/server/cert.pem --keyfile /path/to/server/key.pem
# ```
#
function rabbitmq.ssl_options {
  stdlib.subtitle "rabbitmq.ssl_options"

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
  stdlib.options.create_option state                "present"
  stdlib.options.create_option keyfile              "__required__"
  stdlib.options.create_option certfile             "__required__"
  stdlib.options.create_option file                 "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.create_option cacertfile
  stdlib.options.create_option verify
  stdlib.options.create_option fail_if_no_peer_cert
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="rabbitmq.ssl_options"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  stdlib.resource.process "rabbitmq.ssl_options" "$_name"
}

function rabbitmq.ssl_options.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the ssl options exist
  for i in cacertfile certfile keyfile verify fail_if_no_peer_cert; do
    if [[ -n ${options[$i]} ]]; then
      stdlib_current_state=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/ssl_options/$i")
      if [[ $stdlib_current_state == "absent" ]]; then
        return
      fi
    fi
  done

  # Check if the ssl options match
  for i in cacertfile certfile keyfile verify fail_if_no_peer_cert; do
    if [[ -n ${options[$i]} ]]; then
      _result=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/ssl_options/$i[. = '${options[$i]}']")
      if [[ $stdlib_current_state == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
    fi
  done

  stdlib_current_state="present"
}

function rabbitmq.ssl_options.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p $_dir
  fi

  local -a _augeas_commands=()

  # Set each of the ssl options
  for i in cacertfile certfile keyfile verify fail_if_no_peer_cert; do
    if [[ -n ${options[$i]} ]]; then
      _augeas_commands+=("set /files$_file/rabbit/ssl_options/$i '${options[$i]}'")
    fi
  done

  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.ssl_options.update {
  rabbitmq.ssl_options.delete
  rabbitmq.ssl_options.create
}

function rabbitmq.ssl_options.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/ssl_options")
  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.ssl_options $_name with augeas: $_result"
    return
  fi
}
