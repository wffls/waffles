# == Name
#
# stdlib.debconf
#
# === Description
#
# Manages debconf entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name. Required. namevar.
# * package: The package to configure. Required.
# * question: The debconf question. Required.
# * vtype: The vtype of the debconf setting. Required.
# * value: The answer/setting. Required.
# * unseen: Whether to set the setting to unseen.
#
# === Example
#
# ```shell
# stdlib.debconf --package mysql-server --question mysql-server/root_password
#                --vtype password --value mypassword
# ```
#
function stdlib.debconf {
  stdlib.subtitle "stdlib.debconf_selections"

  if ! stdlib.command_exists "debconf-set-selections" ; then
    stdlib.error "Cannot find command: debconf-set-selections."
    return 1
  fi

  local -A options
  stdlib.options.create_option state    "present"
  stdlib.options.create_option name     "__required__"
  stdlib.options.create_option package  "__required__"
  stdlib.options.create_option question "__required__"
  stdlib.options.create_option vtype    "__required__"
  stdlib.options.create_option value    "__required__"
  stdlib.options.create_option unseen
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.debconf/${options[name]}"

  local _value _unseen

  if [[ -n ${options[unseen]} ]]; then
    _unseen="-u"
  else
    _unseen=""
  fi

  stdlib.debconf.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$name state: $stdlib_current_state, should be absent."
      stdlib.debconf.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: present, should be absent."
        stdlib.debconf.delete
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: out of date."
        stdlib.debconf.update
        ;;
    esac
  fi
}

function stdlib.debconf.read {
  local _dc=$(debconf-show "${options[package]}" | grep "${options[question]}:")
  if [[ -z $_dc ]]; then
    stdlib_current_state="absent"
    return
  fi

  _value=$(echo $_dc | cut -d: -f2 | tr -d ' ')
  if [[ ${options[value]} != $_value ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.debconf.create {
  stdlib.capture_error debconf-set-selections $unseen ${options[package]} ${options[question]} ${options[vtype]} ${options[value]}

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.debconf.delete {
  local _script
  read -r -d '' _script<<EOF
echo RESET ${options[question]} | debconf-communicate ${options[package]}
EOF
  stdlib.capture_error "$_script"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
