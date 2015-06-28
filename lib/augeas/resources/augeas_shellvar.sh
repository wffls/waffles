# == Name
#
# augeas.shellvar
#
# === Description
#
# Manages simple k=v settings in a file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * key: The key. Required. namevar.
# * value: A value for the key. Required.
# * file: The file to add the variable to. Required. namevar.
#
# === Example
#
# ```shell
# augeas.shellvar --key foo --value bar --file /root/vars
# ```
#
function augeas.shellvar {
  stdlib.subtitle "augeas.shellvar"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state "present"
  stdlib.options.create_option key   "__required__"
  stdlib.options.create_option value "__required__"
  stdlib.options.create_option file  "__required__"
  stdlib.options.parse_options "$@"

  local _name="${options[file]}.${options[key]}"
  stdlib.catalog.add "augeas.shellvar/$_name"

  augeas.shellvar.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      augeas.shellvar.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        augeas.shellvar.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        augeas.shellvar.delete
        augeas.shellvar.create
        ;;
    esac
  fi
}

function augeas.shellvar.read {
  local _result

  # Check if the key exists
  stdlib_current_state=$(augeas.get --lens Shellvars --file "${options[file]}" --path "/${options[key]}")
  if [[ $stdlib_current_state == absent ]]; then
    return
  fi

  # Check if the value matches
  _result=$(augeas.get --lens Shellvars --file "${options[file]}" --path "/${options[key]}[. = '${options[value]}']")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
  fi
}

function augeas.shellvar.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Shellvars --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding shellvar $_name with augeas: $_result"
    return
  fi
}

function augeas.shellvar.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${options[file]}/${options[key]}")
  local _result=$(augeas.run --lens Shellvars --file ${options[file]} "${_augeas_commands[@]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting shellvar $_name with augeas: $_result"
    return
  fi
}
