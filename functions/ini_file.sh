# Functions to manipulate INI-style files

ini_file.get_option() {
  # Parameters
  local _file=$1
  local _section=$2
  local _option=$3
  local _line=""

  if [ ! -f "${_file}" ]; then
    echo $_line
    return 1
  fi

  _option=$(echo ${_option} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  if [[ ${_section} != "__none__" ]]; then
    _line=$(sed -ne "/^\[${_section}\]/,/^\[.*\]/ { /^${_option}\([ \t]*=\|$\)/ p; }" "${_file}")
  else
    _line=$(sed "/^\[/q" "${_file}" | sed -ne "/^${_option}[ \t]*/ p;")
  fi

  echo $_line
}

ini_file.option_has_value() {
  # Parameters
  local _file=$1
  local _section=$2
  local _option=$3
  local _value=$4

  if [ ! -f "${_file}" ]; then
    return 1
  fi

  local _line
  local _value=$(echo ${_value} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  local _option=$(echo ${_option} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  if [[ ${_section} != "__none__" ]]; then
    if [[ ${_value} == "__none__" ]]; then
      _line=$(sed -ne "/^\[${_section}\]/,/^\[.*\]/ { /^${_option}$/ p; }" "${_file}")
    else
      _line=$(sed -ne "/^\[${_section}\]/,/^\[.*\]/ { /^${_option}[ \t]*=[ \t]*${_value}$/ p; }" "${_file}")
    fi
  else
    if [[ ${_value} == "__none__" ]]; then
      _line=$(sed -ne "/^${_option}$/ p;" "${_file}")
    else
      _line=$(sed -ne "/^${_option}[ \t]*=[ \t]*${_value}$/ p;" "${_file}")
    fi
  fi

  if [[ -n $_line ]]; then
    return 0
  else
    return 1
  fi
}

ini_file.has_section() {
  # Parameters
  local _file=$1
  local _section=$2

  [[ -n $(grep "^\[${_section}\]" ${_file} 2>/dev/null) ]]
}

ini_file.remove() {
  # Parameters
  local _file=$1
  local _section=$2
  local _option=$3

  if [ ! -f "${_file}" ]; then
    return
  fi

  [[ -z ${_option} ]] && return

  if [[ ${_section} != "__none__" ]]; then
    exec.capture_error "sed -i -e \"/^\[${_section}\]/,/^\[.*\]/ { /^${_option}[ \t]*/ d; }\" \"${_file}\""
  else
    exec.capture_error "sed -i -e \"/^${_option}[ \t]*/ d;\" \"${_file}\""
  fi
}

ini_file.remove_section() {
  # Parameters
  local _file=$1
  local _section=$2

  if [ ! -f "${_file}" ]; then
    return 1
  fi

  exec.capture_error "sed -i -e \"/^\[${_section}\]/ d;\" \"${_file}\""
}

ini_file.set() {
  # Parameters
  local _file=$1
  local _section=$2
  local _option=$3
  local _value=$4

  if [ ! -f "${_file}" ]; then
    return 1
  fi

  if [[ -n $(ini_file.get_option "${_file}" "${_section}" "${_option}") ]]; then
    ini_file.remove "${_file}" "${_section}" "${_option}"
  fi

  [[ -z ${_option} ]] && return
  local _value=$(echo ${_value} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  local _option=$(echo ${_option} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  local _cmd
  if [[ ${_section} != "__none__" ]]; then
    # Add the section if it doesn't exist
    if ! grep -q "^\[${_section}\]" "${_file}" 2>/dev/null; then
      exec.capture_error "echo -e \"\n[${_section}]\" >>\"${_file}\""
    fi

    if [[ $_value == "__none__" ]]; then
      # Add it
      _cmd="sed -i -e \"/^\[${_section}\]/ a\\
${_option}
\" \"${_file}\""
    else
      # Add it
      _cmd="sed -i -e \"/^\[${_section}\]/ a\\
${_option}=${_value}
\" \"${_file}\""
    fi
    exec.capture_error "$_cmd"
  else
    local _newval="${_option}"
    if [[ $_value != "__none__" ]]; then
      _newval="${_option}=${_value}"
    fi

    # if there are sections insert before the first section
    local _result=""
    _result=$(grep "^\[" "${_file}" 2>/dev/null) || true
    if [[ -n $_result ]]; then
      exec.capture_error "sed -i \"0,/^\[/{s/^\[/${_newval}\n&/}\" \"${_file}\""
    else # append to file
      exec.capture_error "echo \"${_newval}\" >> \"${_file}\""
    fi
  fi
}

ini_file.beautify() {
  # Parameters
  local _file=$1
  # Remove all empty lines
  sed -i '/^$/d' "${_file}"
  # Insert an empty line before every '['
  sed -i '/^\[/{x;p;x;}' "${_file}"
  # Remove all leading lines
  sed -i '/./,$!d' "${_file}"
}
