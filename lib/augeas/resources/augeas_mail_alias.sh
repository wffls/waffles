# == Name
#
# augeas.mail_alias
#
# === Description
#
# Manages aliases in /etc/aliases
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * account: The mail account. Required. namevar.
# * destination: The destination for the account. Required.
# * file: The aliases file. Default: /etc/aliases.
#
# === Example
#
# ```shell
# augeas.mail_alias --account root --destination /dev/null
# ```
#
function augeas.mail_alias {
  stdlib.subtitle "augeas.mail_alias"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.set_option state       "present"
  stdlib.options.set_option account     "__required__"
  stdlib.options.set_option destination "__required__"
  stdlib.options.set_option file        "/etc/aliases"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "augeas.mail_alias/${options[account]}"

  augeas.mail_alias.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[account]} state: $stdlib_current_state, should be absent."
      augeas.mail_alias.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[account]} state: absent, should be present."
        augeas.mail_alias.create
        ;;
      present)
        stdlib.debug "${options[account]} state: present."
        ;;
      update)
        stdlib.info "${options[account]} state: present, needs updated."
        augeas.mail_alias.update
        ;;
    esac
  fi
}

function augeas.mail_alias.read {
  local _result

  stdlib_current_state=$(augeas.get --lens Aliases --file "${options[file]}" --path "*/name[. = '${options[account]}']")
  if [[ $stdlib_current_state == absent ]]; then
    return
  fi

  _result=$(augeas.get --lens Aliases --file "${options[file]}" --path "*/name[. = '${options[account]}']/../value[. = '${options[destination]}']")
  if [[ $_result == absent ]]; then
    stdlib_current_state="update"
  fi
}

function augeas.mail_alias.create {
  local _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/01/name '${options[account]}'")
  _augeas_commands+=("set /files${options[file]}/01/value '${options[destination]}'")

  local _result=$(augeas.run --lens Aliases --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error creating mail alias with augeas: $_result"
    return
  fi
}

function augeas.mail_alias.update {
  local _result=$(
    augeas.update --lens Aliases \
                  --file ${options[file]} \
                  --path "*/name[. = '${options[account]}']/../value" \
                  --value "${options[destination]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error updating resource with augeas: $_result"
    return
  fi
}

function augeas.mail_alias.delete {
  local _result=$(
    augeas.delete --lens Aliases \
                  --file ${options[file]} \
                  --path "*/name[. = '${options[account]}']/../")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting resource with augeas: $_result"
    return
  fi
}
