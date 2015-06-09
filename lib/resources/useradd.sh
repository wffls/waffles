# == Name
#
# useradd
#
# === Description
#
# Manages users
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The user Required. namevar.
# * uid: The uid of the user Optional.
# * gid: The gid of the user Optional.
# * createhome: Whether to create the homedir. Default: false.
# * sudo: Whether to give sudo ability: Default: false.
# * shell: The shell of the user. Default /usr/sbin/nologin.
# * comment: The comment field. Optional.
# * homedir: The homedir of the user. Optional.
# * passwd: The password hash. Optional.
# * groups: Supplemental groups of the user. Optional.
#
# === Example
#
# stdlib.useradd --user jdoe --uid 999 --createhome true --homedir /home/jdoe
#                --shell /bin/bash --comment "John Doe"
#
function stdlib.useradd {
  stdlib.subtitle "stdlib.useradd"

  local -A options
  stdlib.options.set_option state      "present"
  stdlib.options.set_option user       "__required__"
  stdlib.options.set_option createhome "false"
  stdlib.options.set_option sudo       "false"
  stdlib.options.set_option shell      "/usr/sbin/nologin"
  stdlib.options.set_option uid
  stdlib.options.set_option gid
  stdlib.options.set_option comment
  stdlib.options.set_option homedir
  stdlib.options.set_option passwd
  stdlib.options.set_option groups
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.useradd/${options[user]}"

  local  user_info passwd_info
  local _user _uid _gid _comment _homedir _shell _sudo _createhome
  local _passwd _pw_change _pw_min_age _pw_max_age _pw_warn _pw_inact _acc_expires
  local _groups

  if [[ ${options[createhome]} == true ]]; then
    _createhome="-m"
  else
    _createhome=""
  fi

  stdlib.useradd.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[user]} state: $stdlib_current_state, should be absent."
      stdlib.useradd.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[user]} state: absent, should be present."
        stdlib.useradd.create
        ;;
      present)
        stdlib.debug "${options[user]} state: present."
        ;;
      update)
        stdlib.info "${options[user]} state: out of date."
        stdlib.useradd.update
        ;;
    esac
  fi
}

function stdlib.useradd.read {
  getent passwd "${options[user]}" &> /dev/null
  if [[ $? != 0 ]]; then
    stdlib_current_state="absent"
    return
  fi

  user_info=$(getent passwd "${options[user]}")
  if [[ -n $user_info ]]; then
    stdlib.split "$user_info" ':'
    _uid="${__split[2]}"
    _gid="${__split[3]}"
    _comment="${__split[4]}"
    _homedir="${__split[5]}"
    _shell="${__split[6]}"

    passwd_info=$(getent shadow "$user")
    stdlib.split "$passwd_info" ':'
    _passwd="${__split[1]}"
    _pw_change="${__split[2]}"
    _pw_min_age="${__split[3]}"
    _pw_max_age="${__split[4]}"
    _pw_warn="${__split[5]}"
    _pw_inact="${__split[6]}"
    _acc_expire="${__split[7]}"

    _groups=$(id -nG "${options[user]}")
  fi

  if [[ -n ${options[uid]} && ${options[uid]} != $_uid ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ -n ${options[homedir]} && ${options[homedir]} != $_homedir ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ -n ${options[shell]} && ${options[shell]} != $_shell ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ -n ${options[passwd]} && ${options[passwd]} != $_passwd ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib.split "${options[groups]}" ','
  declare group_update=false
  for i in "${__split[@]}"; do
    echo "$_groups" | grep -q "$i"
    if [[ $? != 0 ]]; then
      group_update=true
    fi
  done

  if [[ $group_update == true ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ ${options[sudo]} == true && ! -f /etc/sudoers.d/${options[user]} ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.useradd.create {
  declare -a create_args
  if [[ -n ${options[uid]} ]]; then
    create_args+=("-u ${options[uid]}")
  fi

  if [[ -n ${options[gid]} ]]; then
    create_args+=("-g ${options[gid]}")
  fi

  if [[ -n ${options[homedir]} ]]; then
    create_args+=("-d ${options[homedir]}")
  fi

  if [[ -n ${options[shell]} ]]; then
    create_args+=("-s ${options[shell]}")
  fi

  if [[ -n ${options[passwd]} ]]; then
    create_args+=("-p \"${options[passwd]}\"")
  fi

  if [[ -n ${options[comment]} ]]; then
    create_args+=("-c \"${options[comment]}\"")
  fi

  if [[ -n ${options[groups]} ]]; then
    create_args+=("-G ${options[groups]}")
  fi

  stdlib.debug "Creating user ${options[user]}"
  if stdlib.noop? ; then
    stdlib.info "(noop) would have created user ${options[user]} with args ${create_args[@]}"
  else
    stdlib.capture_error useradd $_createhome ${create_args[@]} "${options[user]}"
  fi

  if [[ -n ${options[sudo]} && ${options[sudo]} == true ]]; then
    if stdlib.noop? ; then
      stdlib.info "(noop) would have added ${options[user]} to sudoers"
    else
      stdlib.capture_error echo "${options[user]} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${options[user]}"
    fi
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.useradd.update {
  declare -a update_args
  if [[ -n ${options[uid]} && ${options[uid]} != $_uid ]]; then
    update_args+=("-u ${options[uid]}")
  fi

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    update_args+=("-g ${options[gid]}")
  fi

  if [[ -n ${options[homedir]} && ${options[homedir]} != $_homedir ]]; then
    update_args+=("-d ${options[homedir]}")
  fi

  if [[ -n ${options[shell]} && ${options[shell]} != $_shell ]]; then
    update_args+=("-s ${options[shell]}")
  fi

  if [[ -n ${options[passwd]} && ${options[passwd]} != $_passwd ]]; then
    update_args+=("-p ${options[passwd]}")
  fi

  stdlib.split "${options[groups]}" ','
  declare group_update=false
  for i in "${__split[@]}"; do
    echo "$_groups" | grep -q "$i"
    if [[ $? != 0 ]]; then
      group_update=true
    fi
  done

  if [[ $group_update == true ]]; then
    update_args+=("-G ${options[groups]}")
  fi

  stdlib.debug "Updating user ${options[user]}"
  if stdlib.noop? ; then
    stdlib.info "(noop) would have updated user ${options[user]} with args ${update_args[@]}"
  else
    stdlib.capture_error usermod "${update_args[@]}" "${options[user]}"
  fi

  if [[ ${options[sudo]} == true && ! -f /etc/sudoers.d/${options[user]} ]]; then
    if stdlib.noop? ; then
      stdlib.info "(noop) would have added ${options[user]} to sudoers"
    else
      stdlib.capture_error echo "${options[user]} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${options[user]}"
    fi
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.useradd.delete {
  if stdlib.noop? ; then
    stdlib.info "(noop) would have deleted ${options[user]}"
  else
    stdlib.capture_error userdel -f "${options[user]}"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
