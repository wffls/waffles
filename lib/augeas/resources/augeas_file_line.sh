# == Name
#
# augeas.file_line
#
# === Description
#
# Manages single lines in a file
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name for the line. Required. namevar.
# * line: The line to manage in the file. Required.
# * file: The file to add the line. Required. namevar.
#
# === Example
#
# ```shell
# augeas.file_line --file /root/foo.txt --line "Hello, World!"
# ```
#
function augeas.file_line {
  stdlib.subtitle "augeas.file_line"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option state "present"
  stdlib.options.create_option name  "__required__"
  stdlib.options.create_option line  "__required__"
  stdlib.options.create_option file  "__required__"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "augeas.file_line/${options[name]}"

  augeas.file_line.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      augeas.file_line.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        augeas.file_line.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: present, needs updated."
        augeas.file_line.delete
        augeas.file_line.create
        ;;
    esac
  fi
}

function augeas.file_line.read {
  local _result

  # Check if the line exists
  stdlib_current_state=$(augeas.get --lens Simplelines --file "${options[file]}" --path "/*[. = '${options[line]}']")
}

function augeas.file_line.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files${options[file]}/01 '${options[line]}'")

  local _result=$(augeas.run --lens Simplelines --file "${options[file]}" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding file_line ${options[name]} with augeas: $_result"
    return
  fi
}

function augeas.file_line.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${options[file]}/*[. = '${options[line]}']")
  local _result=$(augeas.run --lens Simplelines --file ${options[file]} "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting file_line ${options[name]} with augeas: $_result"
    return
  fi
}
