# == Name
#
# stdlib.directory
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
# * mode: The perms/mode of the directory. Default: 750.
# * name: The destination directory. Required. namevar.
# * source: Optional source directory to copy.
# * recurse: Whether to apply all settings recursively. Optional.
# * parent: Whether to make the parent directories. Optional.
#
# === Example
#
# ```shell
# stdlib.directory --source $WAFFLES_SITE_DIR/profiles/foo/files/mydir --name /var/lib/mydir
# ```
#
function stdlib.directory {
  stdlib.subtitle "stdlib.directory"

  # Resource Options
  local -A options
  stdlib.options.create_option state     "present"
  stdlib.options.create_option owner     "root"
  stdlib.options.create_option group     "root"
  stdlib.options.create_option mode      "750"
  stdlib.options.create_option name "__required__"
  stdlib.options.create_option recurse   "false"
  stdlib.options.create_option parent    "false"
  stdlib.options.create_option source
  stdlib.options.parse_options "$@"

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
  stdlib.resource.process "stdlib.directory" "${options[name]}"
}

function stdlib.directory.read {
  if [[ ! -d "${options[name]}" ]]; then
    stdlib_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[name]}")
  stdlib.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"

  if [[ $_type != "directory" ]]; then
    stdlib.error "${options[name]} is not a regular directory"
    stdlib_current_state="error"
    return
  fi

  if [[ ${options[owner]} != $_owner ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ ${options[group]} != $_group ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ ${options[mode]} != $_mode ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ -n ${options[source]} ]]; then
    _rsync=$(rsync -ani "${options[source]}/" "${options[name]}")
    if [[ -n $_rsync ]]; then
      stdlib_current_state="update"
      return
    fi
  fi

  stdlib_current_state="present"
}

function stdlib.directory.create {
  if [[ -n ${options[source]} ]]; then
    stdlib.capture_error rsync -a "${options[source]}/" "${options[name]}"
    stdlib.capture_error chmod $_recurse ${options[mode]} "${options[name]}"
    stdlib.capture_error chown $_recurse ${options[owner]}:${options[group]} "${options[name]}"
  else
    stdlib.capture_error mkdir $_parent "${options[name]}"
    stdlib.capture_error chmod ${options[mode]} "${options[name]}"
    stdlib.capture_error chown ${options[owner]}:${options[group]} "${options[name]}"
  fi
}

function stdlib.directory.update {
  if [[ ${options[owner]} != $_owner ]]; then
    stdlib.capture_error chown $_recurse ${options[owner]} "${options[name]}"
  fi

  if [[ ${options[group]} != $_group ]]; then
    stdlib.capture_error chgrp $_recurse ${options[group]} "${options[name]}"
  fi

  if [[ ${options[mode]} != $_mode ]]; then
    stdlib.capture_error chmod $_recurse ${options[mode]} "${options[name]}"
  fi

  if [[ -n $_rsync ]]; then
    stdlib.capture_error rsync -a "${options[source]}/" "${options[name]}"
  fi
}

function stdlib.directory.delete {
  stdlib.capture_error rm -rf "${options[name]}"
}
