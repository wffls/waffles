# == Name
#
# os.useradd
#
# === Description
#
# Manages users
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The user Required.
# * uid: The uid of the user Optional.
# * gid: The gid of the user Optional.
# * createhome: Whether to create the homedir. Default: false.
# * sudo: Whether to give sudo ability: Default: false.
# * shell: The shell of the user. Default /usr/sbin/nologin.
# * comment: The comment field. Optional.
# * homedir: The homedir of the user. Optional.
# * passwd: The password hash. Optional.
# * groups: Supplemental groups of the user. Optional.
# * system: Whether the user is a system user or not. Default: false
#
# === Example
#
# ```shell
# os.useradd --user jdoe --uid 999 --createhome true --homedir /home/jdoe
#                --shell /bin/bash --comment "John Doe"
# ```
#
# === Notes
#
# The `--system true` flag is only useful during a create. If the user already
# exists and you choose to change it into a system using with the `--system`
# flag, it's best to delete the user and recreate it.
#
function os.useradd {
  # Declare the resource
  waffles_resource="os.useradd"

  # Resource Options
  local -A options
  waffles.options.create_option state      "present"
  waffles.options.create_option user       "__required__"
  waffles.options.create_option createhome "false"
  waffles.options.create_option sudo       "false"
  waffles.options.create_option shell      "/usr/sbin/nologin"
  waffles.options.create_option system     "false"
  waffles.options.create_option uid
  waffles.options.create_option gid
  waffles.options.create_option comment
  waffles.options.create_option homedir
  waffles.options.create_option passwd
  waffles.options.create_option groups
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local  user_info passwd_info
  local _user _uid _gid _comment _homedir _shell _sudo _createhome
  local _passwd _pw_change _pw_min_age _pw_max_age _pw_warn _pw_inact _acc_expires
  local _groups

  # Internal Resource configuration
  if [[ ${options[createhome]} == "true" ]]; then
    _createhome="-m"
  else
    _createhome=""
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[user]}"
}

function os.useradd.read {
  getent passwd "${options[user]}" &> /dev/null
  if [[ $? != 0 ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  user_info=$(getent passwd "${options[user]}")
  if [[ -n $user_info ]]; then
    string.split "$user_info" ':'
    _uid="${__split[2]}"
    _gid="${__split[3]}"
    _comment="${__split[4]}"
    _homedir="${__split[5]}"
    _shell="${__split[6]}"

    passwd_info=$(getent shadow "$user")
    string.split "$passwd_info" ':'
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
    waffles_resource_current_state="update"
    return
  fi

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ -n ${options[homedir]} && ${options[homedir]} != $_homedir ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ -n ${options[shell]} && ${options[shell]} != $_shell ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ -n ${options[passwd]} && ${options[passwd]} != $_passwd ]]; then
    waffles_resource_current_state="update"
    return
  fi

  string.split "${options[groups]}" ','
  declare group_update=false
  for i in "${__split[@]}"; do
    echo "$_groups" | grep -q "$i"
    if [[ $? != 0 ]]; then
      group_update=true
    fi
  done

  if [[ $group_update == "true" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ ${options[sudo]} == "true" && ! -f "/etc/sudoers.d/${options[user]}" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function os.useradd.create {
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

  if [[ ${options[system]} == "true" ]]; then
    create_args+=("-r")
  fi

  log.debug "Creating user ${options[user]}"
  exec.capture_error useradd $_createhome ${create_args[@]} "${options[user]}"

  if [[ -n ${options[sudo]} && ${options[sudo]} == "true" ]]; then
    exec.capture_error echo "${options[user]} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${options[user]}"
  fi
}

function os.useradd.update {
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

  string.split "${options[groups]}" ','
  declare group_update=false
  for i in "${__split[@]}"; do
    echo "$_groups" | grep -q "$i"
    if [[ $? != 0 ]]; then
      group_update=true
    fi
  done

  if [[ $group_update == "true" ]]; then
    update_args+=("-G ${options[groups]}")
  fi

  log.debug "Updating user ${options[user]}"
  exec.capture_error usermod "${update_args[@]}" "${options[user]}"

  if [[ ${options[sudo]} == "true" && ! -f "/etc/sudoers.d/${options[user]}" ]]; then
    exec.capture_error echo "${options[user]} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${options[user]}"
  fi
}

function os.useradd.delete {
  exec.capture_error userdel -f "${options[user]}"
}
