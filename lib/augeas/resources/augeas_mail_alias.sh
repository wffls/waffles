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
# * destination: The destination for the account. Required. Multi-value.
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
  local -a destination
  stdlib.options.create_option    state       "present"
  stdlib.options.create_option    account     "__required__"
  stdlib.options.create_mv_option destination "__required__"
  stdlib.options.create_option    file        "/etc/aliases"
  stdlib.options.parse_options    "$@"

  for d in "${destination[@]}"; do
    stdlib.catalog.add "augeas.mail_alias/${options[account]}/${d}"
  done

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

  for d in "${destination[@]}"; do
    _result=$(augeas.get --lens Aliases --file "${options[file]}" --path "*/name[. = '${options[account]}']/../value[. = '$d']")
    if [[ $_result == absent ]]; then
      stdlib_current_state="update"
    fi
  done
}

function augeas.mail_alias.create {
  local _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/01/name '${options[account]}'")

  for d in "${destination[@]}"; do
    _augeas_commands+=("set /files${options[file]}/01/value[0] '$d'")
  done

  local _result=$(augeas.run --lens Aliases --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error creating mail alias with augeas: $_result"
    return
  fi
}

function augeas.mail_alias.update {
  local _augeas_commands=()

  for d in "${destination[@]}"; do
    _augeas_commands+=("set /files${options[file]}/*/name[. = '${options[account]}']/../value[. = '$d'] '$d'")
  done

  local _result=$(augeas.run --lens Aliases --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error creating mail alias with augeas: $_result"
    return
  fi
}

function augeas.mail_alias.delete {
  local _augeas_commands=()
  for d in "${destination[@]}"; do
    _augeas_commands+=("rm /files${options[file]}/*/name[. = '${options[account]}']/../value[. = '$d']")
  done

  local _result=$(augeas.run --lens Aliases --file ${options[file]} "${_augeas_commands[@]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting resource with augeas: $_result"
    return
  fi
}
