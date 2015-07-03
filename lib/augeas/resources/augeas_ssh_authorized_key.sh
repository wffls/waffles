# == Name
#
# augeas.ssh_authorized_key
#
# === Description
#
# Manages ssh_authorized_keys
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The ssh_authorized_key. Required. namevar.
# * key: The ssh key. Required.
# * type: The key type. Required.
# * options: A CSV list of ssh_authorized_key options. Optional
# * file: The ssh_authorized_keys file. Required.
#
# === Example
#
# ```shell
# augeas.ssh_authorized_key --name jdoe --key "AAAAB3NzaC1..." --type ssh-rsa --comment "jdoe@laptop"
# ```
#
# === Notes
#
# TODO: `options` have not been tested.
#
function augeas.ssh_authorized_key {
  stdlib.subtitle "augeas.ssh_authorized_key"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option name    "__required__"
  stdlib.options.create_option key     "__required__"
  stdlib.options.create_option type    "__required__"
  stdlib.options.create_option options ""
  stdlib.options.create_option file    "__required__"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "augeas.ssh_authorized_key/${options[name]}"

  augeas.ssh_authorized_key.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be absent."
      augeas.ssh_authorized_key.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        augeas.ssh_authorized_key.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: present, needs updated."
        augeas.ssh_authorized_key.delete
        augeas.ssh_authorized_key.create
        ;;
    esac
  fi
}

function augeas.ssh_authorized_key.read {
  local _result

  # Check if the key exists
  stdlib_current_state=$(augeas.get --lens Authorized_Keys --file "${options[file]}" --path "/key[. ='${options[key]}']")
  if [[ "$stdlib_current_state" != "present" ]]; then
    return
  fi

  # If the key exists, check if the type matches
  _result=$(augeas.get --lens Authorized_Keys --file "${options[file]}" --path "/key[. ='${options[key]}']/type[. = '${options[type]}']")
  if [[ "$_result" != "present" ]]; then
    stdlib_current_state="update"
    return
  fi

  # Check if the comment matches
  _result=$(augeas.get --lens Authorized_Keys --file "${options[file]}" --path "/key[. ='${options[key]}']/comment[. = '${options[comment]}']")
  if [[ "$_result" != "present" ]]; then
    stdlib_current_state="update"
    return
  fi

  # Check if all the options match
  if [[ -n "${options[options]}" ]]; then
    stdlib.split ${options[options]} ","
    for 0 in "${__split[@]}"; do
      stdlib_current_state=$(augeas.get --lens Authorized_Keys --file ${options[file]} --path "/key[. = '${options[key]}']/options[. = '${o}']")
      if [[ "$stdlib_current_state" != "present" ]]; then
        stdlib_current_state="update"
        return
      fi
    done
  fi

  stdlib_current_state="present"
}

function augeas.ssh_authorized_key.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/key[last()+1] '${options[key]}'")
  _augeas_commands+=("set /files${options[file]}/key[last()]/type '${options[type]}'")
  _augeas_commands+=("set /files${options[file]}/key[last()]/comment '${options[comment]}'")

  if [[ -n "${options[options]}" ]]; then
    stdlib.split ${options[options]} ","
    for o in "${__split[@]}"; do
      _augeas_commands+=("set /files${options[file]}/key[last()]/option[last()+1] '${o}'")
    done
  fi

  local _result=$(augeas.run --lens Authorized_Keys --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding ssh_authorized_key ${options[name]} with augeas: $_result"
    return
  fi
}

function augeas.ssh_authorized_key.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${options[file]}/key[. = '${options[key]}']")
  local _result=$(augeas.run --lens Authorized_Keys --file ${options[file]} "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting ssh_authorized_key ${options[name]} with augeas: $_result"
    return
  fi
}
