# == Name
#
# os.groupadd
#
# === Description
#
# Manages groups
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * group: The group. Required. namevar.
# * gid: The gid of the group. Optional.
#
# === Example
#
# ```shell
# os.groupadd --group jdoe --gid 999
# ```
#
function os.groupadd {
  waffles.subtitle "os.groupadd"

  # Resource Options
  local -A options
  waffles.options.create_option state "present"
  waffles.options.create_option group "__required__"
  waffles.options.create_option gid
  waffles.options.parse_options "$@"

  # Local Variables
  local group_info _gid

  # Process the resource
  waffles.resource.process "os.groupadd" "${options[group]}"
}

function os.groupadd.read {
  group_info=$(getent group "${options[group]}")
  if [[ $? != 0 ]]; then
    waffles_resource_current_state="absent"
    return
  fi
  string.split "$group_info" ':'
  _gid="${__split[2]}"

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function os.groupadd.create {
  declare -a create_args

  if [[ -n ${options[gid]} ]]; then
    create_args+=("-g ${options[gid]}")
  fi

  exec.capture_error groupadd ${create_args[@]} "${options[group]}"
}

function os.groupadd.update {
  declare -a update_args

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    update_args+=("-g ${options[gid]}")
  fi

  log.debug "Updating group ${options[group]}"
  exec.capture_error groupmod ${create_args[@]} "${options[group]}"
}

function os.groupadd.delete {
  exec.capture_error groupdel -f "${options[group]}"
}
