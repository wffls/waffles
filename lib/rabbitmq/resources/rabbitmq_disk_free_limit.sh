# == Name
#
# rabbitmq.disk_free_limit
#
# === Description
#
# Manages disk_free_limit settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * limit_type: Whether mem_relative or absolute Required.
# * value: The value of the limit_type. Required.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.disk_free_limit --limit_type mem_relative --value 1.0
# ```
#
function rabbitmq.disk_free_limit {
  stdlib.subtitle "rabbitmq.disk_free_limit"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state      "present"
  stdlib.options.create_option limit_type "__required__"
  stdlib.options.create_option value      "__required__"
  stdlib.options.create_option file       "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.parse_options "$@"

  local _name="${options[backend]}"
  stdlib.catalog.add "rabbitmq.disk_free_limit/$_name"

  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  rabbitmq.disk_free_limit.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      rabbitmq.disk_free_limit.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        rabbitmq.disk_free_limit.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        rabbitmq.disk_free_limit.delete
        rabbitmq.disk_free_limit.create
        ;;
    esac
  fi
}

function rabbitmq.disk_free_limit.read {
  local _result
  local _path

  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  case "${options[limit_type]}" in
    "mem_relative")
      _path="/rabbit/disk_free_limit/tuple/value[. = 'mem_relative']"
      stdlib_current_state=$(augeas.get --lens Rabbitmq --file "$_file" --path "$_path")
      if [[ "$stdlib_current_state" == "absent" ]]; then
        return
      fi
      _path="/rabbit/disk_free_limit/tuple/value[. = 'mem_relative']/../value[. = '${options[value]}']"
      _result=$(augeas.get --lens Rabbitmq --file "$_file" --path "$_path")
      if [[ "$_result" == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
      ;;
    "absolute")
      _path="/rabbit/disk_free_limit[. = '${options[value]}']"
      stdlib_current_state=$(augeas.get --lens Rabbitmq --file "$_file" --path "$_path")
      if [[ "$stdlib_current_state" == "absent" ]]; then
        return
      fi
      ;;
  esac

  stdlib_current_state="present"
}

function rabbitmq.disk_free_limit.create {
  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  local -a _augeas_commands=()

  case "${options[limit_type]}" in
    "mem_relative")
      _augeas_commands+=("set /files$_file/rabbit/disk_free_limit/tuple[0]/value[0] 'mem_relative'")
      _augeas_commands+=("set /files$_file/rabbit/disk_free_limit/tuple/value[. = 'mem_relative']/../value[last()+1] '${options[value]}'")
      ;;
    "absolute")
      _augeas_commands+=("set /files$_file/rabbit/disk_free_limit '${options[value]}'")
      ;;
  esac

  stdlib.warn "${_augeas_commands[@]}"
  local _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
    return
  fi
}

function rabbitmq.disk_free_limit.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/rabbit/disk_free_limit")

  local _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting rabbitmq.disk_free_limit $_name with augeas: $_result"
    return
  fi
}
