# == Name
#
# file.ini
#
# === Description
#
# Manages ini files/entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * file: The ini file. Required.
# * section: The ini file section. Use "__none__" to not use a section. Required.
# * option: The ini file setting/option. Required.
# * value: The value of the option. Use "__none__" to not set a value. Required.
#
# === Example
#
# ```shell
# file.ini --file /etc/nova/nova.conf --section DEFAULT --option debug --value True
# ```
#
function file.ini {
  # Declare the resource
  waffles_resource="apt.source"


  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option file    "__required__"
  waffles.options.create_option section "__required__"
  waffles.options.create_option option  "__required__"
  waffles.options.create_option value   "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local name="${options[file]}/${options[section]}/${options[option]}"

  # Process the resource
  waffles.resource.process $waffles_resource "$name"
}

function file.ini.read {
  if [[ ! -f ${options[file]} ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  if ! file.ini.ini_get_option ; then
    waffles_resource_current_state="absent"
    return
  fi

  if ! file.ini.ini_option_has_value ; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function file.ini.create {
  if waffles.noop ; then
    log.info "(noop) Would have added $name."
  else
    file.ini.iniset
  fi
}

function file.ini.update {
  if waffles.noop ; then
    log.info "(noop) Would have changed $name."
  else
    file.ini.iniset
  fi
}

function file.ini.delete {
  if waffles.noop ; then
    log.info "(noop) Would have changed $name."
  else
    file.ini.inidelete
  fi
}

# The following were modified from
# https://raw.githubusercontent.com/openstack-dev/devstack/master/inc/ini-config
function file.ini.ini_get_option {
  local _line
  local _option=$(echo ${options[option]} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  if [[ ${options[section]} != "__none__" ]]; then
    _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${_option}\([ \t]*=\|$\)/ p; }" "${options[file]}")
  else
    _line=$(sed -ne "/^${_option}[ \t]*/ p;"  "${options[file]}")
  fi

  [[ -n $_line ]]

}

function file.ini.ini_option_has_value {
  local _line
  local _value=$(echo ${options[value]} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  local _option=$(echo ${options[option]} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  if [[ ${options[section]} != "__none__" ]]; then
    if [[ ${options[value]} == "__none__" ]]; then
      _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${_option}$/ p; }" "${options[file]}")
    else
      _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${_option}[ \t]*=[ \t]*${_value}$/ p; }" "${options[file]}")
    fi
  else
    if [[ ${options[value]} == "__none__" ]]; then
      _line=$(sed -ne "/^${_option}$/ p;" "${options[file]}")
    else
      _line=$(sed -ne "/^${_option}[ \t]*=[ \t]*${_value}$/ p;" "${options[file]}")
    fi
  fi

  [[ -n $_line ]]
}

function file.ini.inidelete {
  [[ -z ${options[option]} ]] && return
  if [[ ${options[section]} != "__none__" ]]; then
    sed -i -e "/^\[${options[section]}\]/,/^\[.*\]/ { /^${options[option]}[ \t]*=/ d; }" "${options[file]}"
  else
    sed -i -e "/^${options[option]}[ \t]*=/ d;" "${options[file]}"
  fi
}

function file.ini.iniset {
  [[ -z ${options[option]} ]] && return
  local _value=$(echo ${options[value]} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  local _option=$(echo ${options[option]} | sed -e 's/[\/&]/\\&/g' | sed -e 's/[][]/\\&/g')
  if [[ ${options[section]} != "__none__" ]]; then
    # Add the section if it doesn't exist
    if ! grep -q "^\[${options[section]}\]" "${options[file]}" 2>/dev/null; then
      echo -e "\n[${options[section]}]" >>"${options[file]}"
    fi

    if [[ $waffles_resource_current_state != "absent" ]]; then
      file.ini.inidelete
    fi

    if [[ $_value == "__none__" ]]; then
      # Add it
      sed -i -e "/^\[${options[section]}\]/ a\\
${_option}
" "${options[file]}"
    else
      # Add it
      sed -i -e "/^\[${options[section]}\]/ a\\
${_option} = $_value
" "${options[file]}"
    fi
  else
    if [[ $waffles_resource_current_state != "absent" ]]; then
      file.ini.inidelete
    fi

    if ! grep -q "^${options[option]}" "${options[file]}" 2>/dev/null; then
      echo "${options[option]} = ${options[value]}" >>"${options[file]}"
    else
      sed -i "1s/^/${options[option]} = $_value\n/" ${options[file]}
    fi
  fi
}
