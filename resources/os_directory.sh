# == Name
#
# os.directory
#
# === Description
#
# Manages directories
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * owner: The owner of the directory. Default: root.
# * group: The group of the directory. Default: root.
# * mode: The perms/mode of the directory. Default: 0750.
# * name: The destination directory. Required.
# * source: Optional source directory to copy.
# * recurse: Whether to apply all settings recursively. Optional.
# * parent: Whether to make the parent directories. Optional.
#
# === Example
#
# ```bash
# os.directory --source "$profile_files/mydir" --name /var/lib/mydir
# ```
#
os.directory() {
  # Declare the resource
  waffles_resource="os.directory"

  # Resource Options
  local -A options
  waffles.options.create_option state     "present"
  waffles.options.create_option owner     "root"
  waffles.options.create_option group     "root"
  waffles.options.create_option mode      "0750"
  waffles.options.create_option name      "__required__"
  waffles.options.create_option recurse   "false"
  waffles.options.create_option parent    "false"
  waffles.options.create_option source
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Check if all dependencies are installed
  # This is done out of order of other resources to allow os.directory
  # to run without rsync unless the --source option is used.
  if [[ -n ${options[source]} ]]; then
    local _wrd=("rsync")
    if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
      return 1
    fi
  fi

  # Local Variables
  local _owner=""
  local _group=""
  local _mode=""
  local _source=""
  local _directory=""
  local _recurse=""
  local _rsync=""
  local _parent=""

  # Internal Resource Configuration
  if [[ ${options[recurse]} == "true" ]]; then
    _recurse="-R"
  else
    _recurse=""
  fi

  if [[ ${options[parent]} == "true" ]]; then
    _parent="-p"
  else
    _parent=""
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

os.directory.read() {
  local _wrcs=""

  if [[ ! -d "${options[name]}" ]]; then
    _wrcs="absent"
  fi

  if [[ -z $_wrcs ]]; then
    _stats=$(stat -c"%U:%G:%a:%F" "${options[name]}")
    string.split "$_stats" ':'
    _owner="${__split[0]}"
    _group="${__split[1]}"
    _mode="${__split[2]}"
    _type="${__split[3]}"

    if [[ $_type != "directory" ]]; then
      log.error "${options[name]} is not a regular directory"
      waffles_resource_current_state="error"
      return
    fi
  fi

  if [[ -z $_wrcs && ${options[owner]} != $_owner ]]; then
    _wrcs="update"
  fi

  if [[ -z $_wrcs && ${options[group]} != $_group ]]; then
    _wrcs="update"
  fi

  if [[ -z $_wrcs && ${options[mode]} != $_mode ]] && [[ ${options[mode]} != "0${_mode}" ]]; then
    _wrcs="update"
  fi

  if [[ -z $_wrcs && -n ${options[source]} ]]; then
    _rsync=$(rsync -ani "${options[source]}/" "${options[name]}")
    if [[ -n $_rsync ]]; then
      _wrcs="update"
    fi
  fi

  if [[ -z $_wrcs ]]; then
    _wrcs="present"
  fi

  waffles_resource_current_state="$_wrcs"
}

os.directory.create() {
  if [[ -n ${options[source]} ]]; then
    exec.capture_error rsync -a "${options[source]}/" "${options[name]}"
    exec.capture_error chmod $_recurse ${options[mode]} "${options[name]}"
    exec.capture_error chown $_recurse ${options[owner]}:${options[group]} "${options[name]}"
  else
    exec.capture_error mkdir $_parent "${options[name]}"
    exec.capture_error chmod ${options[mode]} "${options[name]}"
    exec.capture_error chown ${options[owner]}:${options[group]} "${options[name]}"
  fi
}

os.directory.update() {
  if [[ ${options[owner]} != $_owner ]]; then
    exec.capture_error chown $_recurse ${options[owner]} "${options[name]}"
  fi

  if [[ ${options[group]} != $_group ]]; then
    exec.capture_error chgrp $_recurse ${options[group]} "${options[name]}"
  fi

  if [[ ${options[mode]} != $_mode ]] && [[ ${options[mode]} != "0${_mode}" ]]; then
    exec.capture_error chmod $_recurse ${options[mode]} "${options[name]}"
  fi

  if [[ -n $_rsync ]]; then
    exec.capture_error rsync -a "${options[source]}/" "${options[name]}"
  fi
}

os.directory.delete() {
  exec.capture_error rm -rf "${options[name]}"
}
