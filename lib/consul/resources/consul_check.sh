# == Name
#
# consul.check
#
# === Description
#
# Manages a consul.check.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the check Required. namevar.
# * id: A unique ID for the check. Optional.
# * service_id: A service to tie the check to. Optional.
# * notes: Notes about the check. Optional.
# * token: An ACL token. Optional.
# * check: The script or http location for the check. Optional.
# * type: The type of check: script, http, or ttl. Required.
# * interval: The interval to run the script. Optional.
# * ttl: The TTL of the check. Optional.
# * file: The file to store the check in. Required. Defaults to /etc/consul.d/check-name.json
#
# === Example
#
# ```shell
# consul.check --name mysql \
#              --check "/usr/local/bin/check_mysql.sh" \
#              --type "script" \
#              --interval "60s"
# ```
#
function consul.check {
  stdlib.subtitle "consul.check"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state      "present"
  stdlib.options.create_option name       "__required__"
  stdlib.options.create_option type       "__required__"
  stdlib.options.create_option id
  stdlib.options.create_option service_id
  stdlib.options.create_option notes
  stdlib.options.create_option token
  stdlib.options.create_option check
  stdlib.options.create_option interval
  stdlib.options.create_option ttl
  stdlib.options.create_option file
  stdlib.options.parse_options "$@"

  local _name="${options[name]}"
  stdlib.catalog.add "consul.check/${options[name]}"

  local _file
  if [[ -z "${options[file]}" ]]; then
    _file="/etc/consul.d/check-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  local _dir=$(dirname "${options[file]}")

  local _simple_options=(name id notes token interval ttl)

  consul.check.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      consul.check.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        consul.check.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        consul.check.delete
        consul.check.create
        ;;
    esac
  fi
}

function consul.check.read {
  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if simple options exist and match
  for _o in "${_simple_options[@]}"; do
    if [[ -n "${options[$_o]}" ]]; then
      _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'check']/dict/entry[. = '$_o']/*[. = '${options[$_o]}']")
      if [[ "$_result" == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
    fi
  done

  # Check if check exist, if it's not of type ttl
  if [[ "${options[type]}" != "ttl" ]]; then
    _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'check']/dict/entry[. = '${options[type]}']/string[. = '${options[check]}']")
    if [[ "$_result" == "absent" ]]; then
      stdlib_current_state="update"
      return
    fi
  fi

  if [[ "$stdlib_current_state" == "update" ]]; then
    return
  else
    stdlib_current_state="present"
  fi
}

function consul.check.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  if [[ ! -f "$_file" ]]; then
    stdlib.debug "Creating empty JSON file."
    stdlib.mute "echo '{}' > $_file"
    _augeas_commands+=("rm /files/${_file}/dict")
  fi

  # Create the check entry
  _augeas_commands+=("set /files/${_file}/dict/entry 'check'")
  _augeas_commands+=("touch /files/${_file}/dict/entry[. = 'check']/dict")

  # Create the simple options
  for _o in "${_simple_options[@]}"; do
    if [[ -n "${options[$_o]}" ]]; then
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'check']/dict/entry[. = '$_o'] '$_o'")
      _augeas_commands+=("set /files/${_file}/dict/entry[. = 'check']/dict/entry[. = '$_o']/string '${options[$_o]}'")
    fi
  done

  # Add check
  if [[ "${options[type]}" != "ttl" ]]; then
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'check']/dict/entry[. = '${options[type]}'] '${options[type]}'")
    _augeas_commands+=("set /files/${_file}/dict/entry[. = 'check']/dict/entry[. = '${options[type]}']/string '${options[check]}'")
  fi

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function consul.check.delete {
  local _result
  local -a _augeas_commands=()

  _augeas_commands+=("rm /files/${_file}/dict/entry[. = 'check']")

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
