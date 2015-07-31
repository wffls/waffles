# == Name
#
# stdlib.ini
#
# === Description
#
# Manages ini files/entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * file: The ini file. Required.
# * section: The ini file section. Required.
# * option: The ini file setting/option. Required.
# * value: The value of the option. Use "__none__" to not set a value. Required.
#
# === Example
#
# ```shell
# stdlib.ini --file /etc/nova/nova.conf --section DEFAULT --option debug --value True
# ```
#
function stdlib.ini {
  stdlib.subtitle "stdlib.ini"

  # Resource Options
  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option file    "__required__"
  stdlib.options.create_option section "__required__"
  stdlib.options.create_option option  "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.parse_options "$@"

  # Local Variables
  local name="${options[file]}/${options[section]}/${options[option]}"

  # Process the resource
  stdlib.resource.process "stdlib.ini" "$name"
}

function stdlib.ini.read {
  if [[ ! -f ${options[file]} ]]; then
    stdlib_current_state="absent"
    return
  fi

  if ! stdlib.ini.ini_get_option ; then
    stdlib_current_state="absent"
    return
  fi

  if ! stdlib.ini.ini_option_has_value ; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.ini.create {
  if stdlib.noop? ; then
    stdlib.info "(noop) Would have added $name."
  else
    stdlib.ini.iniset
  fi
}

function stdlib.ini.update {
  if stdlib.noop? ; then
    stdlib.info "(noop) Would have changed $name."
  else
    stdlib.ini.iniset
  fi
}

function stdlib.ini.delete {
  if stdlib.noop? ; then
    stdlib.info "(noop) Would have changed $name."
  else
    stdlib.ini.inidelete
  fi
}

# The following were modified from
# https://raw.githubusercontent.com/openstack-dev/devstack/master/inc/ini-config
function stdlib.ini.ini_get_option {
  local _line
  if [[ -n ${options[section]} ]]; then
    _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${options[option]}\([ \t]*=\|$\)/ p; }" "${options[file]}")
  else
    _line=$(sed -ne "/^${options[option]}[ \t]*/ p;"  "${options[file]}")
  fi

  [[ -n $_line ]]

}

function stdlib.ini.ini_option_has_value {
  local _line
  local _value=$(echo ${options[value]} | sed -e 's/[\/&]/\\&/g')
  if [[ -n ${options[section]} ]]; then
    if [[ ${options[value]} == "__none__" ]]; then
      _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${options[option]}$/ p; }" "${options[file]}")
    else
      _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${options[option]}[ \t]*=[ \t]*${_value}$/ p; }" "${options[file]}")
    fi
  else
    if [[ ${options[value]} == "__none__" ]]; then
      _line=$(sed -ne "/^${options[option]}$/ p;" "${options[file]}")
    else
      _line=$(sed -ne "/^${options[option]}[ \t]*=[ \t]*${_value}$/ p;" "${options[file]}")
    fi
  fi

  [[ -n $_line ]]
}

function stdlib.ini.inidelete {
  [[ -z ${options[option]} ]] && return
  if [[ -n ${options[section]} ]]; then
    sed -i -e "/^\[${options[section]}\]/,/^\[.*\]/ { /^${options[option]}[ \t]*=/ d; }" "${options[file]}"
  else
    sed -i -e "/^${options[option]}[ \t]*=/ d;" "${options[file]}"
  fi
}

function stdlib.ini.iniset {
  [[ -z ${options[option]} ]] && return
  if [[ -n ${options[section]} ]]; then
    # Add the section if it doesn't exist
    if ! grep -q "^\[${options[section]}\]" "${options[file]}" 2>/dev/null; then
      echo -e "\n[${options[section]}]" >>"${options[file]}"
    fi

    if [[ $stdlib_current_state != "absent" ]]; then
      stdlib.ini.inidelete
    fi

    if [[ ${options[value]} == "__none__" ]]; then
      # Add it
      sed -i -e "/^\[${options[section]}\]/ a\\
${options[option]}
" "${options[file]}"
    else
      # Add it
      sed -i -e "/^\[${options[section]}\]/ a\\
${options[option]} = ${options[value]}
" "${options[file]}"
    fi
  else
    if [[ $stdlib_current_state != "absent" ]]; then
      stdlib.ini.inidelete
    fi

    echo -e "${options[option]} = ${options[value]}" >> "${options[file]}"
  fi
}
