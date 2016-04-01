# == Name
#
# rabbitmq.cluster_nodes
#
# === Description
#
# Manages cluster_nodes settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * node: A node. Required. Multi-var.
# * cluster_type: The cluster type. Optional. Defaults to disc.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.cluster_nodes --node rabbit@my.host.com --node rabbit@my2.host.com --cluster_type ram
# ```
#
function rabbitmq.cluster_nodes {
  waffles.subtitle "rabbitmq.cluster_nodes"

  if ! waffles.command_exists augtool ; then
    log.error "Cannot find augtool."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  local -a node
  waffles.options.create_option state        "present"
  waffles.options.create_mv_option node      "__required__"
  waffles.options.create_option cluster_type "__required__"
  waffles.options.create_option file         "/etc/rabbitmq/rabbitmq.config"
  waffles.options.parse_options "$@"

  # Local Variables
  local _name="rabbitmq.cluster_nodes"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  waffles.resource.process "rabbitmq.cluster_nodes" "$_name"
}

function rabbitmq.cluster_nodes.read {
  local _result

  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the path exists in augeas
  waffles_resource_current_state=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/cluster_nodes/tuple")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if the nodes exist
  for n in "${node[@]}"; do
    _result=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/cluster_nodes/tuple/value[1]/value[. = '$n']")
    if [[ $_result == "absent" ]]; then
      waffles_resource_current_state="update"
      return
    fi
  done

  # Check if the cluster type matches
  _result=$(augeas.get --lens Rabbitmq --file $_file --path "/rabbit/cluster_nodes/tuple/value[2][. = '${options[cluster_type]}']")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function rabbitmq.cluster_nodes.create {
  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p $_dir
  fi

  local -a _augeas_commands=()

  for n in "${node[@]}"; do
    _augeas_commands+=("set /files$_file/rabbit/cluster_nodes/tuple/value[1]/value[0] '$n'")
  done
  _augeas_commands+=("set /files$_file/rabbit/cluster_nodes/tuple/value[2] '${options[cluster_type]}'")

  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.cluster_nodes.update {
  rabbitmq.cluster_nodes.delete
  rabbitmq.cluster_nodes.create
}

function rabbitmq.cluster_nodes.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/cluster_nodes")
  local _result=$(augeas.run --lens Rabbitmq --file $_file "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting rabbitmq.cluster_nodes $_name with augeas: $_result"
    return
  fi
}
