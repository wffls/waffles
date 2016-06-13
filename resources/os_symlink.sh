# == Name
#
# os.symlink
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
# os.symlink --source /usr/local/bin/foo --destination /usr/bin/foo
# ```
#
function os.symlink {

  # Resource Options
  local -A options
  waffles.options.create_option state       "present"
  waffles.options.create_option source      "__required__"
  waffles.options.create_option destination "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Internal Resource Configuration
  if [[ ! -f ${options[source]} ]]; then
    log.error "${options[source]} does not exist."
    return 1
  fi

  # Process the resource
  waffles.resource.process "os.symlink" "${options[destination]}"
}

function os.symlink.read {
  if [[ ! -e ${options[destination]} ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[destination]}")
  string.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"

  if [[ $_type != "symbolic link" ]]; then
    log.error "${options[destination]} exists and is not a symbolic link."
    waffles_resource_current_state="error"
    return
  fi

  waffles_resource_current_state="present"
}

function os.symlink.create {
  exec.capture_error ln -s "${options[source]}" "${options[destination]}"
}

function os.symlink.update {
  os.symlink.delete
  os.symlink.create
}

function os.symlink.delete {
  exec.capture_error rm "${options[destination]}"
}
