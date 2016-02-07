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
# * package: The package to configure. Required.
# * question: The debconf question. Required.
# * vtype: The vtype of the debconf setting. Required.
# * value: The answer/setting. Required.
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
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state    "present"
  stdlib.options.create_option package  "__required__"
  stdlib.options.create_option question "__required__"
  stdlib.options.create_option vtype    "__required__"
  stdlib.options.create_option value    "__required__"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _value _name

  # Internal Resource Configuration
  if [[ -n ${options[unseen]} ]]; then
    _unseen="-u"
  else
    _unseen=""
  fi

  _name="${options[package]}/${options[question]}/${options[vtype]}"

  # Process the resource
  stdlib.resource.process "stdlib.debconf" "$_name"
}

function stdlib.debconf.read {
  local _dc=$(echo get ${options[question]} | debconf-communicate ${options[package]} 2>/dev/null)
  if [[ $_dc =~ ^10 ]]; then
    stdlib_current_state="absent"
  elif [[ $_dc == "0" ]]; then
    stdlib_current_state="absent"
  elif [[ $_dc == "0 ${options[value]}" ]]; then
    stdlib_current_state="present"
  else
    stdlib_current_state="update"
  fi
}

function stdlib.debconf.create {
  local _script
  read -r -d '' _script<<EOF
echo ${options[package]} ${options[question]} ${options[vtype]} "${options[value]}" | debconf-set-selections
EOF
  stdlib.capture_error "$_script"
}

function stdlib.debconf.update {
  stdlib.debconf.delete
  stdlib.debconf.create
}

function stdlib.debconf.delete {
  local _script
  read -r -d '' _script<<EOF
echo RESET ${options[question]} | debconf-communicate ${options[package]}
EOF
  stdlib.capture_error "$_script"
}
