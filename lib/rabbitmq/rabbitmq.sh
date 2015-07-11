function rabbitmq.generic_value_read {
  if [[ $# -ne 3 ]]; then
    stdlib.error "rabbitmq.generic_value file key value"
    return 1
  fi

  local _file="$1"
  local _key="$2"
  local _value="$3"
  local _state

  _state=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/${_key}")
  if [[ "$_state" == "absent" ]]; then
    stdlib_current_state="absent"
    return
  fi

  _state=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/${_key}[. = '${_value}']")
  if [[ "$_state" == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.list_value_read {
  if [[ $# -ne 3 ]]; then
    stdlib.error "rabbitmq.list_value file key value"
    return 1
  fi

  local _file="$1"
  local _key="$2"
  local _value="$3"
  local _state

  _state=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/${_key}")
  if [[ "$_state" == "absent" ]]; then
    stdlib_current_state="absent"
    return
  fi

  _state=$(augeas.get --lens Rabbitmq --file "$_file" --path "/rabbit/${_key}/value[. = '${_value}']")
  if [[ "$_state" == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.generic_value_create {
  if [[ $# -ne 3 ]]; then
    stdlib.error "rabbitmq.generic_value file key value"
    return 1
  fi

  local _file="$1"
  local _key="$2"
  local _value="$3"
  local -a _augeas_commands=()

  _augeas_commands+=("set /files${_file}/rabbit/${_key} '${_value}'")
  _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")
}

function rabbitmq.list_value_create {
  if [[ $# -ne 3 ]]; then
    stdlib.error "rabbitmq.list_value file key value"
    return 1
  fi

  local _file="$1"
  local _key="$2"
  local _value="$3"
  local -a _augeas_commands=()

  _augeas_commands+=("set /files${_file}/rabbit/${_key}/value[0] '${_value}'")
  _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")
}

function rabbitmq.generic_value_delete {
  if [[ $# -ne 3 ]]; then
    stdlib.error "rabbitmq.generic_value file key value"
    return 1
  fi

  local _file="$1"
  local _key="$2"
  local _value="$3"
  local -a _augeas_commands=()

  _augeas_commands+=("rm /files${_file}/rabbit/${_key}")
  stdlib.info "${_augeas_commands[@]}"
  _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")
}

function rabbitmq.list_value_delete {
  if [[ $# -ne 3 ]]; then
    stdlib.error "rabbitmq.generic_value file key value"
    return 1
  fi

  local _file="$1"
  local _key="$2"
  local _value="$3"
  local -a _augeas_commands=()

  _augeas_commands+=("rm /files${_file}/rabbit/${_key}/value[. = '${_value}']")
  stdlib.info "${_augeas_commands[@]}"
  _result=$(augeas.run --lens Rabbitmq --file "$_file" "${_augeas_commands[@]}")
}
