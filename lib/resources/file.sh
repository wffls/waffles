# == Name
#
# stdlib.file
#
# === Description
#
# Manages files
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * owner: The owner of the directory. Default: root.
# * group: The group of the directory. Default: root.
# * mode: The perms/mode of the directory. Default: 750.
# * name: The destination file. Required. namevar.
# * content: STDIN content for the file. Optional.
# * source: Source directory to copy. Optional.
#
# === Example
#
# ```shell
# stdlib.file --file /etc/foobar --content "Hello, World!"
# ```
#
function stdlib.file {
  stdlib.subtitle "stdlib.file"

  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option owner   "root"
  stdlib.options.create_option group   "root"
  stdlib.options.create_option mode    "640"
  stdlib.options.create_option name    "__required__"
  stdlib.options.create_option content
  stdlib.options.create_option source
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.file/${options[name]}"

  local _owner _group _mode _name md5 _md5

  if [[ -n ${options[source]} && -n ${options[content]} ]]; then
    stdlib.error "Cannot have both source and content set for a file."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  if [[ -n ${options[source]} ]]; then
    if [[ ! -f "${options[source]}" ]]; then
      stdlib.error "${options[source]} does not exist."
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    fi
  fi

  stdlib.file.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be absent."
      stdlib.file.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        stdlib.file.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: out of date."
        stdlib.file.update
        ;;
      type_error)
        stdlib.info "${options[name]} state: not a regular file."
        ;;
    esac
  fi
}

function stdlib.file.read {
  if [[ ! -f ${options[name]} ]]; then
    stdlib_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[name]}")
  stdlib.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"
  _md5=$(md5sum "${options[name]}" | cut -d' ' -f1)

  if [[ -n "${options[source]}" ]]; then
    md5=$(md5sum "${options[source]}" | cut -d' ' -f1)
  fi

  if [[ -n "${options[content]}" ]]; then
    md5=$(echo "${options[content]}" | md5sum | cut -d' ' -f1)
  fi

  if [[ "$_type" != "regular file" ]]; then
    stdlib_current_state="type_error"
    return
  fi

  if [[ "${options[owner]}" != "$_owner" ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ "${options[group]}" != "$_group" ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ "${options[mode]}" != "$_mode" ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ -n "$_md5" ]]; then
    if [[ "$md5" != "$_md5" ]]; then
      stdlib_current_state="update"
      return
    fi
  fi

  stdlib_current_state="present"
}

function stdlib.file.create {
  if [[ -n "${options[source]}" ]]; then
    stdlib.capture_error cp "${options[source]}" "${options[name]}"
    stdlib.capture_error chmod ${options[mode]} "${options[name]}"
    stdlib.capture_error chown ${options[owner]}:${options[group]} "${options[name]}"
  else
    if [[ -n "${options[content]}" ]]; then
      local _script
      read -r -d '' _script<<EOF
echo '${options[content]}' > "${options[name]}"
EOF
      stdlib.capture_error "$_script"
    else
      stdlib.capture_error touch "${options[name]}"
    fi
    stdlib.capture_error chmod ${options[mode]} "${options[name]}"
    stdlib.capture_error chown ${options[owner]}:${options[group]} "${options[name]}"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.file.update {
  if [[ "${options[owner]}" != "$_owner" ]]; then
    stdlib.capture_error chown ${options[owner]} "${options[name]}"
  fi

  if [[ "${options[group]}" != "$_group" ]]; then
    stdlib.capture_error chgrp ${options[group]} "${options[name]}"
  fi

  if [[ "${options[mode]}" != "$_mode" ]]; then
    stdlib.capture_error chmod ${options[mode]} "${options[name]}"
  fi

  if [[ -n "$_md5" && "$md5" != "$_md5" ]]; then
    if [[ -n "${options[content]}" ]]; then
      local _script
      read -r -d '' _script<<EOF
echo '${options[content]}' > "${options[name]}"
EOF
      stdlib.capture_error "$_script"
    fi
    if [[ -n "${options[source]}" ]]; then
      stdlib.capture_error cp "${options[source]}" "${options[name]}"
    fi
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.file.delete {
  stdlib.capture_error rm -f "${options[name]}"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
