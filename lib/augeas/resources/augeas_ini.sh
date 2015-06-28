# == Name
#
# augeas.ini
#
# === Description
#
# Manages ini file entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * section: The section in the ini file. Required. namevar.
# * option: The option in the ini file. Required. namevar.
# * value: The value of the option. Required.
# * file: The file to add the variable to. Required. namevar.
#
# === Example
#
# ```shell
# augeas.ini --key foo --value bar --file /root/vars
# ```
#
function augeas.ini {
  stdlib.subtitle "augeas.ini"

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
  stdlib.options.create_option section "__required__"
  stdlib.options.create_option option  "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.create_option file    "__required__"
  stdlib.options.parse_options "$@"

  local _name="${options[file]}.${options[section]}.${options[option]}"
  stdlib.catalog.add "augeas.ini/$_name"

  augeas.ini.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      augeas.ini.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        augeas.ini.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        augeas.ini.delete
        augeas.ini.create
        ;;
    esac
  fi
}

function augeas.ini.read {
  local _result

  # Check if the section/option
  stdlib_current_state=$(augeas.get --lens Puppet --file "${options[file]}" --path "/${options[section]}/${options[option]}")
  if [[ $stdlib_current_state == absent ]]; then
    return
  fi

  # Check if the value matches
  _result=$(augeas.get --lens Puppet --file "${options[file]}" --path "/${options[section]}/${options[option]}[. = '${options[value]}']")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
  fi
}

function augeas.ini.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/${options[section]}/${options[option]} '${options[value]}'")

  local _result=$(augeas.run --lens Puppet --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding ini $_name with augeas: $_result"
    return
  fi
}

function augeas.ini.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${options[file]}/${options[section]}/${options[option]}")
  local _result=$(augeas.run --lens Puppet --file ${options[file]} "${_augeas_commands[@]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting ini $_name with augeas: $_result"
    return
  fi
}
