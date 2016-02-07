# == Name
#
# stdlib.file_line
#
# === Description
#
# Manages single lines in a file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * file: The file that the line belongs to. Required.
# * line: The line to manage. Required.
# * match: A regex to match to. Optional.
#
# === Example
#
# ```shell
# stdlib.file_line --file /etc/memcached.conf \
#                  --line "-l 0.0.0.0" --match "^-l"
# ```
#
function stdlib.file_line {
  stdlib.subtitle "stdlib.file_line"

  # Resource Options
  local -A options
  stdlib.options.create_option state  "present"
  stdlib.options.create_option line   "__required__"
  stdlib.options.create_option file   "__required__"
  stdlib.options.create_option match
  stdlib.options.parse_options "$@"

  # Internal Resource Configuration
  local _name="${options[file]}/${options[line]}"

  # Process the resource
  stdlib.resource.process "stdlib.file_line" "$_name"
}

function stdlib.file_line.read {
  if [[ ! -f ${options[file]} ]]; then
    stdlib_current_state="absent"
    return
  fi

  stdlib.debug_mute "grep -qx -- '${options[line]}' '${options[file]}'"
  if [[ $? == 1 ]]; then
    stdlib_current_state="absent"
    return
  fi

  if [[ -n ${options[match]} ]]; then
    stdlib.debug_mute "sed -n -e '/${options[match]}/p' '${options[file]}'"
    if [[ $? == 1 ]]; then
      stdlib.error "No match for ${options[match]} in ${options[file]}"
      if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
        exit 1
      else
        return 1
      fi
    fi
  fi

  stdlib_current_state="present"
}

function stdlib.file_line.create {
  if [[ ! -f ${options[file]} ]]; then
    if [[ -n ${options[match]} ]]; then
      stdlib.warn "${options[file]} does not exist. Cannot match on an empty file. Proceeding without matching."
    fi
    stdlib.capture_error "echo '${options[line]}' > '${options[file]}'"
  else
    if [[ -n ${options[match]} ]]; then
      local _replacement=$(echo ${options[line]} | sed -e 's/[\/&]/\\&/g')
      stdlib.capture_error "sed -i -e '/${options[match]}/c ${_replacement}' '${options[file]}'"
    else
      local _replacement=$(echo ${options[line]} | sed -e 's/[\/&]/\\&/g')
      stdlib.capture_error "sed -i -e '\$a${_replacement}' '${options[file]}'"
    fi
  fi
}

function stdlib.file_line.update {
  stdlib.file_line.create
}

function stdlib.file_line.delete {
  local _replacement=$(echo ${options[line]} | sed -e 's/[\/&]/\\&/g')
  stdlib.capture_error "sed -i -e '/^${options[line]}$/d' '${options[file]}'"
}
