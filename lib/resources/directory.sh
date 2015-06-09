# == Name
#
# directory
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
# stdlib.directory --source modules/mymod/files/foo --name /var/lib/foo
#
function stdlib.directory {
  stdlib.subtitle "stdlib.directory"

  local -A options
  stdlib.options.set_option state     "present"
  stdlib.options.set_option owner     "root"
  stdlib.options.set_option group     "root"
  stdlib.options.set_option mode      "750"
  stdlib.options.set_option name "__required__"
  stdlib.options.set_option recurse   "false"
  stdlib.options.set_option parent    "false"
  stdlib.options.set_option source
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.directory/${options[name]}"

  local _owner _group _mode _source _directory _recurse _rsync _parent

  if [[ ${options[recurse]} == true ]]; then
    _recurse="-R"
  else
    _recurse=""
  fi

  if [[ ${options[parent]} == true ]]; then
    _parent="-p"
  else
    _parent=""
  fi

  stdlib.directory.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be absent."
      stdlib.directory.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        stdlib.directory.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: out of date."
        stdlib.directory.update
        ;;
      type_error)
        stdlib.info "${options[name]} state: not a regular directory."
        ;;
    esac
  fi
}

function stdlib.directory.read {
  if [[ ! -d ${options[name]} ]]; then
    stdlib_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[name]}")
  stdlib.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"

  if [[ $_type != directory ]]; then
    stdlib_current_state="type_error"
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
    stdlib.capture_error chmod ${options[recurse]} ${options[mode]} "${options[name]}"
    stdlib.capture_error chown ${options[recurse]} ${options[owner]}:${options[group]} "${options[name]}"
  else
    stdlib.capture_error mkdir $_parent "${options[name]}"
    stdlib.capture_error chmod ${options[mode]} "${options[name]}"
    stdlib.capture_error chown ${options[group]}:${options[group]} "${options[name]}"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.directory.update {
  if [[ ${options[owner]} != $_owner ]]; then
    stdlib.capture_error chown $recurse ${options[owner]} "${options[name]}"
  fi

  if [[ ${options[group]} != $_group ]]; then
    stdlib.capture_error chgrp $recurse ${options[group]} "$directory"
  fi

  if [[ ${options[mode]} != $_mode ]]; then
    stdlib.capture_error chmod $recurse ${options[mode]} "${options[name]}"
  fi

  if [[ -n $_rsync ]]; then
    stdlib.capture_error rsync -a "${options[source]}/" "${options[name]}"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.directory.delete {
  stdlib.capture_error rm -rf "${options[name]}"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
