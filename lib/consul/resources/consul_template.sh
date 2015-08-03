# == Name
#
# consul.template
#
# === Description
#
# Manages a consul.template.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the template. Required. namevar.
# * source: The source of the template. Optional. Defaults to /etc/consul/template/tpl/name.tpl
# * destination: The destination of the rendered template. Required.
# * command: An optional command to run after the template is rendered. Optional.
# * file: The file to store the template in. Required. Defaults to /etc/consul/template/conf.d/name.json
#
# === Example
#
# ```shell
# consul.template --name hosts \
#                 --destination /etc/hosts
# ```
#
function consul.template {
  stdlib.subtitle "consul.template"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  if ! stdlib.command_exists consul ; then
    stdlib.error "Cannot find consul"
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state       "present"
  stdlib.options.create_option name        "__required__"
  stdlib.options.create_option destination "__required__"
  stdlib.options.create_option source
  stdlib.options.create_option command
  stdlib.options.create_option file
  stdlib.options.parse_options "$@"

  # Local Variables
  local _file _source
  local _name="${options[name]}"
  local _simple_options=(destination source command)

  # Internal Resource configuration
  if [[ -z ${options[file]} ]]; then
    _file="/etc/consul/template/conf.d/template-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  if [[ -z ${options[source]} ]]; then
    options[source]="/etc/consul/template/tpl/${options[name]}.tpl"
  fi

  # Process the resource
  stdlib.resource.process "consul.template" "$_name"
}

function consul.template.read {
  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if simple options exist and match
  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _result=$(augeas.get --lens Json --file "$_file" --path "/dict/entry[. = 'template']/array/dict/entry[. = '$_o']/*[. = '${options[$_o]}']")
      if [[ $_result == "absent" ]]; then
        stdlib_current_state="update"
        return
      fi
    fi
  done

  if [[ $stdlib_current_state == "update" ]]; then
    return
  else
    stdlib_current_state="present"
  fi
}

function consul.template.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -f $_file ]]; then
    stdlib.debug "Creating empty JSON file."
    stdlib.mute "echo '{}' > $_file"
    _augeas_commands+=("rm /files/$_file/dict")
  fi

  # Create the check entry
  _augeas_commands+=("set /files/$_file/dict/entry 'template'")
  _augeas_commands+=("touch /files/$_file/dict/entry[. = 'template']/array")

  # Create the simple options
  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _augeas_commands+=("set /files/$_file/dict/entry[. = 'template']/array/dict/entry[. = '$_o'] '$_o'")
      _augeas_commands+=("set /files/$_file/dict/entry[. = 'template']/array/dict/entry[. = '$_o']/string '${options[$_o]}'")
    fi
  done

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function consul.template.update {
  consul.template.delete
  consul.template.create
}

function consul.template.delete {
  local _result
  local -a _augeas_commands=()

  _augeas_commands+=("rm /files/$_file/dict")

  _result=$(augeas.run --lens Json --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}
