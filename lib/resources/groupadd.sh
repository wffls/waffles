# == Name
#
# stdlib.groupadd
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
# stdlib.groupadd --group jdoe --gid 999
# ```
#
function stdlib.groupadd {
  stdlib.subtitle "stdlib.groupadd"

  # Resource Options
  local -A options
  stdlib.options.create_option state "present"
  stdlib.options.create_option group "__required__"
  stdlib.options.create_option gid
  stdlib.options.parse_options "$@"

  # Local Variables
  local group_info _gid

  # Process the resource
  stdlib.resource.process "stdlib.groupadd" "${options[group]}"
}

function stdlib.groupadd.read {
  group_info=$(getent group "${options[group]}")
  if [[ $? != 0 ]]; then
    stdlib_current_state="absent"
    return
  fi
  stdlib.split "$group_info" ':'
  _gid="${__split[2]}"

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.groupadd.create {
  declare -a create_args

  if [[ -n ${options[gid]} ]]; then
    create_args+=("-g ${options[gid]}")
  fi

  stdlib.capture_error groupadd ${create_args[@]} "${options[group]}"
}

function stdlib.groupadd.update {
  declare -a update_args

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    update_args+=("-g ${options[gid]}")
  fi

  stdlib.debug "Updating group ${options[group]}"
  stdlib.capture_error groupmod ${create_args[@]} "${options[group]}"
}

function stdlib.groupadd.delete {
  stdlib.capture_error groupdel -f "${options[group]}"
}
