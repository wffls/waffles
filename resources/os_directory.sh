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
# ```shell
# os.directory --source "$profile_files/mydir" --name /var/lib/mydir
# ```
#
function os.directory {
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


  # Local Variables
  local _owner _group _mode _source _directory _recurse _rsync _parent

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

function os.directory.read {
  if [[ ! -d "${options[name]}" ]]; then
    waffles_resource_current_state="absent"
    return
  fi

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

  if [[ ${options[owner]} != $_owner ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ ${options[group]} != $_group ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ ${options[mode]} != $_mode ]] && [[ ${options[mode]} != "0${_mode}" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ -n ${options[source]} ]]; then
    _rsync=$(rsync -ani "${options[source]}/" "${options[name]}")
    if [[ -n $_rsync ]]; then
      waffles_resource_current_state="update"
      return
    fi
  fi

  waffles_resource_current_state="present"
}

function os.directory.create {
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

function os.directory.update {
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

function os.directory.delete {
  exec.capture_error rm -rf "${options[name]}"
}
