# == Name
#
# augeas.host
#
# === Description
#
# Manages hosts in /etc/hosts
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The host. Required. namevar.
# * ip: The IP address of the host. Required.
# * aliases: A CSV list of host aliases. Optional
# * file: The hosts file. Default: /etc/hosts.
#
# === Example
#
# ```shell
# augeas.host --name example.com --ip 192.168.1.1 --aliases www,db
# ```
#
function augeas.host {
  stdlib.subtitle "augeas.host"

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
  stdlib.options.create_option ip      "__required__"
  stdlib.options.create_option aliases ""
  stdlib.options.create_option file    "/etc/hosts"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "augeas.host/${options[name]}"

  augeas.host.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be absent."
      augeas.host.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        augeas.host.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: present, needs updated."
        augeas.host.delete
        augeas.host.create
        ;;
    esac
  fi
}

function augeas.host.read {
  stdlib_current_state=$(augeas.get --lens Hosts --file "${options[file]}" --path "*/canonical[. = '${options[name]}']/../ipaddr")
  if [[ "$stdlib_current_state" != "present" ]]; then
    return
  fi

  if [[ -n "${options[aliases]}" ]]; then
    stdlib.split ${options[aliases]} ","
    for a in "${__split[@]}"; do
      _result=$(augeas.get --lens Hosts --file "${options[file]}" --path "*/canonical[. = '${options[name]}']/alias[. = '${a}']")
      if [[ "$_result" != "present" ]]; then
        stdlib_current_state="update"
        return
      fi
    done
  fi

  stdlib_current_state="present"
}

function augeas.host.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/01/ipaddr '${options[ip]}'")
  _augeas_commands+=("set /files${options[file]}/01/canonical '${options[name]}'")

  if [[ -n "${options[aliases]}" ]]; then
    stdlib.split ${options[aliases]} ","
    for a in "${__split[@]}"; do
      _augeas_commands+=("set /files${options[file]}/01/alias[last()+1] '${a}'")
    done
  fi

  local _result=$(augeas.run --lens Hosts --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding creating alias with augeas: $_result"
    return
  fi
}

function augeas.host.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${options[file]}/*/canonical[. = '${options[name]}']/../")

  local _result=$(augeas.run --lens Hosts --file ${options[file]} "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting resource with augeas: $_result"
    return
  fi
}
