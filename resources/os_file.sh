# == Name
#
# os.file
#
# === Description
#
# Manages files
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * owner: The owner of the file Default: root.
# * group: The group of the file Default: root.
# * mode: The perms/mode of the file Default: 0640.
# * name: The destination file. Required.
# * content: STDIN content for the file. Optional.
# * source: Source file to copy. Optional.
#
# === Example
#
# ```shell
# os.file --name /etc/foobar --content "Hello, World!"
# ```
#
os.file() {
  # Declare the resource
  waffles_resource="os.file"

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option owner   "root"
  waffles.options.create_option group   "root"
  waffles.options.create_option mode    "0640"
  waffles.options.create_option name    "__required__"
  waffles.options.create_option content
  waffles.options.create_option source
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _owner _group _mode _name md5 _md5

  # Internal Resource Configuration
  if [[ -n ${options[source]} && -n ${options[content]} ]]; then
    log.error "Cannot have both source and content set for a file."
    return 1
  fi

  if [[ -n ${options[source]} ]]; then
    if [[ ! -f ${options[source]} ]]; then
      log.error "${options[source]} does not exist."
      return 1
    fi
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

os.file.read() {
  if [[ ! -f ${options[name]} ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[name]}")
  string.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"
  _md5=$(md5sum "${options[name]}" | cut -d' ' -f1)

  if [[ -n ${options[source]} ]]; then
    md5=$(md5sum "${options[source]}" | cut -d' ' -f1)
  fi

  if [[ -n ${options[content]} ]]; then
    md5=$(echo "${options[content]}" | md5sum | cut -d' ' -f1)
  fi

  if [[ $_type != "regular file" ]] && [[ $_type != "regular empty file" ]]; then
    log.error "${options[name]} is not a regular file."
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

  if [[ -n $md5 ]]; then
    if [[ $md5 != $_md5 ]]; then
      waffles_resource_current_state="update"
      return
    fi
  fi

  waffles_resource_current_state="present"
}

os.file.create() {
  if [[ -n ${options[source]} ]]; then
    exec.capture_error cp "${options[source]}" "${options[name]}"
    exec.capture_error chmod ${options[mode]} "${options[name]}"
    exec.capture_error chown ${options[owner]}:${options[group]} "${options[name]}"
  else
    if [[ -n ${options[content]} ]]; then
      echo "${options[content]}" > "${options[name]}"
      local _ret="$?"
      if [[ $_ret != 0 ]]; then
        log.error "Errors occurred writing content to file."
        return $_ret
      fi
    else
      exec.capture_error touch "${options[name]}"
    fi
    exec.capture_error chmod ${options[mode]} "${options[name]}"
    exec.capture_error chown ${options[owner]}:${options[group]} "${options[name]}"
  fi
}

os.file.update() {
  if [[ ${options[owner]} != $_owner ]]; then
    exec.capture_error chown ${options[owner]} "${options[name]}"
  fi

  if [[ ${options[group]} != $_group ]]; then
    exec.capture_error chgrp ${options[group]} "${options[name]}"
  fi

  if [[ ${options[mode]} != $_mode ]] && [[ ${options[mode]} != "0${_mode}" ]]; then
    exec.capture_error chmod ${options[mode]} "${options[name]}"
  fi

  if [[ -n $_md5 && $md5 != $_md5 ]]; then
    if [[ -n ${options[content]} ]]; then
      echo "${options[content]}" > "${options[name]}"
      local _ret="$?"
      if [[ $_ret != 0 ]]; then
        log.error "Errors occurred writing content to file."
        return $_ret
      fi
    fi

    if [[ -n ${options[source]} ]]; then
      exec.capture_error cp "${options[source]}" "${options[name]}"
    fi
  fi
}

os.file.delete() {
  exec.capture_error rm -f "${options[name]}"
}
