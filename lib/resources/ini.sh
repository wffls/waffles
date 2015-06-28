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
# * value: The value of the option. Required.
#
# === Example
#
# ```shell
# stdlib.ini --file /etc/nova/nova.conf --section DEFAULT --option debug --value True
# ```
#
function stdlib.ini {
  stdlib.subtitle "stdlib.ini"

  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option file    "__required__"
  stdlib.options.create_option section "__required__"
  stdlib.options.create_option option  "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.parse_options "$@"

  local name="${options[file]}/${options[section]}/${options[option]}"

  stdlib.catalog.add "stdlib.ini/$name"

  stdlib.ini.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$name state: $stdlib_current_state, should be absent."
      stdlib.ini.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$name state: absent, should be present."
        stdlib.ini.create
        ;;
      present)
        stdlib.debug "$name state: present."
        ;;
      update)
        stdlib.info "$name state: out of date."
        stdlib.ini.update
        ;;
    esac
  fi
}

function stdlib.ini.read {
  if [[ ! -f ${options[file]} ]]; then
    stdlib_current_state="absent"
    return
  fi

  if ! stdlib.ini.ini_get ; then
    stdlib_current_state="absent"
    return
  fi

  if ! stdlib.ini.ini_has_option ; then
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

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.ini.update {
  if stdlib.noop? ; then
    stdlib.info "(noop) Would have changed $name."
  else
    stdlib.ini.iniset
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.ini.delete {
  if stdlib.noop? ; then
    stdlib.info "(noop) Would have changed $name."
  else
    stdlib.ini.inidelete
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

# The following were taken from
# https://raw.githubusercontent.com/openstack-dev/devstack/master/inc/ini-config
function stdlib.ini.ini_get {
  local _line
  if [[ -n ${options[section]} ]]; then
    _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${options[option]}[ \t]*=/ p; }" "${options[file]}")
  else
    _line=$(sed -ne "/^${options[option]}[ \t]*=/ p;"  "${options[file]}")
  fi

  [ -n "$_line" ]

}

function stdlib.ini.ini_has_option {
  local _line
  local _value=$(echo ${options[value]} | sed -e 's/[\/&]/\\&/g')
  if [[ -n ${options[section]} ]]; then
    _line=$(sed -ne "/^\[${options[section]}\]/,/^\[.*\]/ { /^${options[option]}[ \t]*=[ \t]*${_value}$/ p; }" "${options[file]}")
  else
    _line=$(sed -ne "/^${options[option]}[ \t]*=[ \t]*${_value}$/ p;" "${options[file]}")
  fi

  [ -n "$_line" ]
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
    [[ -z ${options[option]} ]] && return

    # Add the section if it doesn't exist
    if ! grep -q "^\[${options[section]}\]" "${options[file]}" 2>/dev/null; then
      echo -e "\n[${options[section]}]" >>"${options[file]}"
    fi

    if [[ $stdlib_current_state == absent ]]; then
      # Add it
      sed -i -e "/^\[${options[section]}\]/ a\\
${options[option]} = ${options[value]}
" "${options[file]}"
    else
      # Replace it
      local sep=$(echo -ne "\x01")
      sed -i -e '/^\['${options[section]}'\]/,/^\[.*\]/ s'${sep}'^\('${options[option]}'[ \t]*=[ \t]*\).*$'${sep}'\1'"${options[value]}"${sep} "${options[file]}"
    fi
  else
    if [[ $stdlib_current_state == absent ]]; then
      # Add it
      echo -e "${options[option]} = ${options[value]}" >> "${options[file]}"
    else
      # Replace it
      local sep=$(echo -ne "\x01")
      sed -i -e 's'${sep}'^\('${options[option]}'[ \t]*=[ \t]*\).*$'${sep}'\1'"${options[value]}"${sep} "${options[file]}"
    fi
  fi
}
