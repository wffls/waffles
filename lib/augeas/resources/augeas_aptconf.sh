# == Name
#
# augeas.aptconf
#
# === Description
#
# Manages apt.conf settings
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * setting: The setting Required. namevar.
# * value: A value for the setting Required.
# * file: The file to add the variable to. Required. namevar.
#
# === Example
#
# ```shell
# augeas.aptconf --setting APT::Periodic::Update-Package-Lists --value 1 --file /etc/apt/apt.conf/20auto-upgrades
# augeas.aptconf --setting APT::Periodic::Unattended-Upgrade --value 1 --file /etc/apt/apt.conf/20auto-upgrades
# ```
#
function augeas.aptconf {
  stdlib.subtitle "augeas.aptconf"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option setting "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.create_option file    "__required__"
  stdlib.options.parse_options "$@"

  #local _path=$(echo ${options[setting]} | sed -e 's/::/\//g')
  local _path=${options[setting]//::/\/}
  stdlib.catalog.add "augeas.aptconf/${options[setting]}"

  augeas.aptconf.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      augeas.aptconf.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        augeas.aptconf.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        augeas.aptconf.delete
        augeas.aptconf.create
        ;;
    esac
  fi
}

function augeas.aptconf.read {
  local _result

  # Check if the setting exists
  stdlib_current_state=$(augeas.get --lens Aptconf --file "${options[file]}" --path "/$_path")
  if [[ $stdlib_current_state == absent ]]; then
    return
  fi

  # Check if the value matches
  _result=$(augeas.get --lens Aptconf --file "${options[file]}" --path "/${_path}[. = '${options[value]}']")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
  fi
}

function augeas.aptconf.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/$_path '${options[value]}'")

  local _result=$(augeas.run --lens Aptconf --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding aptconf $_name with augeas: $_result"
    return
  fi
}

function augeas.aptconf.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${options[file]}/$_path")
  local _result=$(augeas.run --lens Aptconf --file ${options[file]} "${_augeas_commands[@]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting aptconf $_name with augeas: $_result"
    return
  fi
}
