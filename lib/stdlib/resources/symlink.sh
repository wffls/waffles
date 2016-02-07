# == Name
#
# stdlib.symlink
#
# === Description
#
# Manages symlinks
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * destination: The destination link. Required. namevar.
# * source: Source file. Required.
#
# === Example
#
# ```shell
# stdlib.symlink --source /usr/local/bin/foo --destination /usr/bin/foo
# ```
#
function stdlib.symlink {
  stdlib.subtitle "stdlib.symlink"

  # Resource Options
  local -A options
  stdlib.options.create_option state       "present"
  stdlib.options.create_option source      "__required__"
  stdlib.options.create_option destination "__required__"
  stdlib.options.parse_options "$@"

  # Internal Resource Configuration
  if [[ ! -f ${options[source]} ]]; then
    stdlib.error "${options[source]} does not exist."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Process the resource
  stdlib.resource.process "stdlib.symlink" "${options[destination]}"
}

function stdlib.symlink.read {
  if [[ ! -e ${options[destination]} ]]; then
    stdlib_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[destination]}")
  stdlib.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"

  if [[ $_type != "symbolic link" ]]; then
    stdlib.error "${options[destination]} exists and is not a symbolic link."
    stdlib_current_state="error"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.symlink.create {
  stdlib.capture_error ln -s "${options[source]}" "${options[destination]}"
}

function stdlib.symlink.update {
  stdlib.symlink.delete
  stdlib.symlink.create
}

function stdlib.symlink.delete {
  stdlib.capture_error rm "${options[destination]}"
}
