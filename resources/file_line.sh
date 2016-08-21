# == Name
#
# file.line
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
# ```bash
# file.line --file /etc/memcached.conf \
#           --line "-l 0.0.0.0" --match "^-l"
# ```
#
file.line() {
  # Declare the resource
  waffles_resource="file.line"

  # Check if all dependencies are installed
  local _wrd=("sed" "grep")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state  "present"
  waffles.options.create_option line   "__required__"
  waffles.options.create_option file   "__required__"
  waffles.options.create_option match
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Internal Resource Configuration
  local _name="${options[file]}/${options[line]}"

  # Process the resource
  waffles.resource.process $waffles_resource "$_name"
}

file.line.read() {
  local _wrcs=""

  if [[ ! -f ${options[file]} ]]; then
    _wrcs="absent"
  fi

  if [[ -z $_wrcs ]]; then
    exec.mute "grep -qx -- '${options[line]}' '${options[file]}'" || {
      _wrcs="absent"
    }
  fi

  if [[ -z $_wrcs ]]; then
    if [[ -n ${options[match]} ]]; then
      exec.mute "sed -n -e '/${options[match]}/p' '${options[file]}'" || {
        log.error "No match for ${options[match]} in ${options[file]}"
        return 1
      }
    fi
  fi

  if [[ -z $_wrcs ]]; then
    _wrcs="present"
  fi

  waffles_resource_current_state="$_wrcs"
}

file.line.create() {
  if [[ ! -f ${options[file]} ]]; then
    if [[ -n ${options[match]} ]]; then
      log.warn "${options[file]} does not exist. Cannot match on an empty file. Proceeding without matching."
    fi
    exec.capture_error "echo '${options[line]}' > '${options[file]}'"
  else
    if [[ -n ${options[match]} ]]; then
      local _replacement=$(echo ${options[line]} | sed -e 's/[\/&]/\\&/g')
      exec.capture_error "sed -i -e '/${options[match]}/c ${_replacement}' '${options[file]}'"
    else
      local _replacement=$(echo ${options[line]} | sed -e 's/[\/&]/\\&/g')
      exec.capture_error "sed -i -e '\$a${_replacement}' '${options[file]}'"
    fi
  fi
}

file.line.update() {
  file.line.create
}

file.line.delete() {
  local _replacement=$(echo ${options[line]} | sed -e 's/[\/&]/\\&/g')
  exec.capture_error "sed -i -e '/^${options[line]}$/d' '${options[file]}'"
}
