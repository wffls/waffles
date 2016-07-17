# Functions to manipulate INI-style files

ini_file.get_option() {
  # Parameters
  local _file=$1
  local _section=$2
  local _option=$3

  if [ ! -f "${_file}" ]; then
    echo ""
    return 1
  fi

  local _line
  _option=$(echo ${_option} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  if [[ ${_section} != "__none__" ]]; then
    _line=$(sed -ne "/^\[${_section}\]/,/^\[.*\]/ { /^${_option}\([ \t]*=\|$\)/ p; }" "${_file}")
  else
    _line=$(sed "/^\[/q" "${_file}" | sed -ne "/^${_option}[ \t]*/ p;")
  fi

  if [[ -z $_line ]]; then
    echo ""
    return 2
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

ini_file.remove() {
  # Parameters
  local _file=$1
  local _section=$2
  local _option=$3

  if [ ! -f "${_file}" ]; then
    return 1
  fi

  [[ -z ${_option} ]] && return
  if [[ ${_section} != "__none__" ]]; then
    sed -i -e "/^\[${_section}\]/,/^\[.*\]/ { /^${_option}[ \t]*/ d; }" "${_file}"
  else
    sed -i -e "/^${_option}[ \t]*/ d;" "${_file}"
  fi
}

ini_file.set() {
  # Parameters
  local _file=$1
  local _section=$2
  local _option=$3
  local _value=$4

  if [ ! -f "${_file}" ]; then
    echo ""
    return 1
  fi

  if [[ -n $(ini_file.get_option "${_file}" "${_section}" "${_option}") ]]; then
    ini_file.remove "${_file}" "${_section}" "${_option}"
  fi

  [[ -z ${_option} ]] && return
  local _value=$(echo ${_value} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  local _option=$(echo ${_option} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  if [[ ${_section} != "__none__" ]]; then
    # Add the section if it doesn't exist
    if ! grep -q "^\[${_section}\]" "${_file}" 2>/dev/null; then
      echo -e "\n[${_section}]" >>"${_file}"
    fi

    if [[ $_value == "__none__" ]]; then
      # Add it
      sed -i -e "/^\[${_section}\]/ a\\
${_option}
" "${_file}"
    else
      # Add it
      sed -i -e "/^\[${_section}\]/ a\\
${_option}=${_value}
" "${_file}"
    fi
  else
    local _newval="${_option}"
    if [[ $_value != "__none__" ]]; then
      _newval="${_option}=${_value}"
    fi
    # if there are sections insert before the first section
    if [[ -n $(grep "^\[" "${_file}" 2>/dev/null) ]]; then
      sed -i "0,/^\[/{s/^\[/${_newval}\n&/}" "${_file}"
    else # append to file
      echo "${_newval}" >> "${_file}"
    fi
  fi
}

