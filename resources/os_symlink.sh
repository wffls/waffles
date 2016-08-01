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
# * name: The name of the link. Required.
# * target: The target of the link. Optional.
# * overwrite: Overwrite the link if it already exists. Optional. Defaults to false.
#
# === Example
#
# ```bash
# os.symlink --name /usr/local/man --target /usr/share/man
# ```
#
os.symlink() {
  # Declare the resource
  waffles_resource="os.symlink"

  # Check if all dependencies are installed
  local _wrd=()
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state     "present"
  waffles.options.create_option name      "__required__"
  waffles.options.create_option overwrite "false"
  waffles.options.create_option target
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Internal Resource Configuration
  if [[ ${options[state]} != "absent" ]]; then
    local _err
    if [[ -z ${options[target]} ]]; then
      log.error "target is required unless symlink is being removed."
      _err=true
    elif [[ ! -e ${options[target]} ]]; then
      log.error "${options[target]} does not exist."
      _err=true
    fi

    if [[ -n $_err ]]; then
      return 1
    fi
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

os.symlink.read() {
  local _target

  if [[ ! -e ${options[name]} ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[name]}")
  string.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"

  if [[ $_type != "symbolic link" ]]; then
    log.error "${options[name]} exists and is not a symbolic link."
    waffles_resource_current_state="error"
    return 1
  fi

  _target=$(readlink "${options[name]}")
  if [[ -n ${options[target]} ]] && [[ "$_target" != "${options[target]}" ]]; then
    if [[ "${options[overwrite]}" == "false" ]]; then
      log.error "${options[name]} already points to $_target. Use --overwrite true to overwrite."
      waffles_resource_current_state="error"
      return 1
    else
      waffles_resource_current_state="update"
      return
    fi
  fi

  waffles_resource_current_state="present"
}

os.symlink.create() {
  exec.capture_error ln -s "${options[target]}" "${options[name]}"
}

os.symlink.update() {
  os.symlink.delete
  os.symlink.create
}

os.symlink.delete() {
  exec.capture_error rm "${options[name]}"
}
