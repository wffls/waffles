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
  stdlib.subtitle "rabbitmq.cluster_nodes"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  local -a node
  stdlib.options.create_option state        "present"
  stdlib.options.create_mv_option node      "__required__"
  stdlib.options.create_option cluster_type "__required__"
  stdlib.options.create_option file         "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  local _name="rabbitmq.cluster_nodes"
  stdlib.catalog.add "$_name"

  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  rabbitmq.cluster_nodes.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      rabbitmq.cluster_nodes.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        rabbitmq.cluster_nodes.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        rabbitmq.cluster_nodes.delete
        rabbitmq.cluster_nodes.create
        ;;
    esac
  fi
}

function rabbitmq.cluster_nodes.read {
  local _result

  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the path exists in augeas
  stdlib_current_state=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/cluster_nodes/tuple")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  # Check if the nodes exist
  for n in "${node[@]}"; do
    _result=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/cluster_nodes/tuple/value[1]/value[. = '$n']")
    if [[ "$_result" == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  done

  # Check if the cluster type matches
  _result=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/cluster_nodes/tuple/value[2][. = '${options[cluster_type]}']")
  if [[ "$_result" == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.cluster_nodes.create {
  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  local -a _augeas_commands=()

  for n in "${node[@]}"; do
    _augeas_commands+=("set /files$_file/rabbit/cluster_nodes/tuple/value[1]/value[0] '$n'")
  done
  _augeas_commands+=("set /files$_file/rabbit/cluster_nodes/tuple/value[2] '${options[cluster_type]}'")

  local _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.cluster_nodes.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/cluster_nodes")
  local _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.cluster_nodes $_name with augeas: $_result"
    return
  fi
}
