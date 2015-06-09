# == Name
#
# groupadd
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
# stdlib.groupadd --group jdoe --gid 999
#
function stdlib.groupadd {
  stdlib.subtitle "stdlib.groupadd"

  local -A options
  stdlib.options.set_option state "present"
  stdlib.options.set_option group "__required__"
  stdlib.options.set_option gid
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.groupadd/${options[group]}"

  local group_info _gid

  stdlib.groupadd.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[group]} state: $stdlib_current_state, should be absent."
      stdlib.groupadd.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[group]} state: absent, should be present."
        stdlib.groupadd.create
        ;;
      present)
        stdlib.debug "${options[group]} state: present."
        ;;
      update)
        stdlib.info "${options[group]} state: out of date."
        stdlib.groupadd.update
        ;;
    esac
  fi
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

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.groupadd.update {
  declare -a update_args

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    update_args+=("-g ${options[gid]}")
  fi

  stdlib.debug "Updating group ${options[group]}"
  stdlib.capture_error groupmod ${create_args[@]} "${options[group]}"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.groupadd.delete {
  stdlib.capture_error groupdel -f "${options[group]}"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
