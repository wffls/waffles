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
# ```bash
# os.useradd --user jdoe --uid 999 --createhome true --homedir /home/jdoe \
#            --shell /bin/bash --comment "John Doe"
# ```
#
# === Notes
#
# The `--system true` flag is only useful during a create. If the user already
# exists and you choose to change it into a system using with the `--system`
# flag, it's best to delete the user and recreate it.
#
os.useradd() {
  # Declare the resource
  waffles_resource="os.useradd"

  # Check if all dependencies are installed
  local _wrd=("getent" "useradd" "usermod" "userdel")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 2
  fi

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
  local _user_info=""
  local _passwd_info=""

  local _user=""
  local _uid=""
  local _gid=""
  local _comment=""
  local _homedir=""
  local _shell=""
  local _sudo=""
  local _createhome=""

  local _passwd=""
  local _pw_change=""
  local _pw_min_age=""
  local _pw_max_age=""
  local _pw_warn=""
  local _pw_inact=""
  local _acc_expires=""

  declare -a _groups=()

  # Internal Resource configuration
  if [[ ${options[createhome]} == "true" ]]; then
    _createhome="-m"
  else
    _createhome=""
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[user]}"
}

os.useradd.read() {
  getent passwd "${options[user]}" &> /dev/null || {
    waffles_resource_current_state="absent"
    return
  }

  _user_info=$(getent passwd "${options[user]}")
  if [[ -n $_user_info ]]; then
    string.split "$_user_info" ':'
    _uid="${__split[2]}"
    _gid="${__split[3]}"
    _comment="${__split[4]}"
    _homedir="${__split[5]}"
    _shell="${__split[6]}"

    _passwd_info=$(getent shadow "${options[user]}")
    string.split "$_passwd_info" ':'
    _passwd="${__split[1]}"
    _pw_change="${__split[2]}"
    _pw_min_age="${__split[3]}"
    _pw_max_age="${__split[4]}"
    _pw_warn="${__split[5]}"
    _pw_inact="${__split[6]}"
    _acc_expire="${__split[7]}"

    _groups=($(id -nG "${options[user]}"))
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

  local _group_update=false
  if [[ -n ${options[groups]} ]]; then
    string.split "${options[groups]}" ','
    for i in "${__split[@]}"; do
      if ! array.contains _groups $i ; then
        _group_update=true
      fi
    done
  fi

  if [[ $_group_update == "true" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  if [[ ${options[sudo]} == "true" && ! -f "/etc/sudoers.d/${options[user]}" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

os.useradd.create() {
  declare -a _create_args=()

  if [[ -n ${options[uid]} ]]; then
    _create_args+=("-u ${options[uid]}")
  fi

  if [[ -n ${options[gid]} ]]; then
    _create_args+=("-g ${options[gid]}")
  fi

  if [[ -n ${options[homedir]} ]]; then
    _create_args+=("-d ${options[homedir]}")
  fi

  if [[ -n ${options[shell]} ]]; then
    _create_args+=("-s ${options[shell]}")
  fi

  if [[ -n ${options[passwd]} ]]; then
    _create_args+=("-p \"${options[passwd]}\"")
  fi

  if [[ -n ${options[comment]} ]]; then
    _create_args+=("-c \"${options[comment]}\"")
  fi

  if [[ -n ${options[groups]} ]]; then
    _create_args+=("-G ${options[groups]}")
  fi

  if [[ ${options[system]} == "true" ]]; then
    _create_args+=("-r")
  fi

  log.debug "Creating user ${options[user]}"
  exec.capture_error useradd $_createhome ${_create_args[@]:-} "${options[user]}"

  if [[ -n ${options[sudo]} && ${options[sudo]} == "true" ]]; then
    exec.capture_error echo "${options[user]} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${options[user]}"
  fi
}

os.useradd.update() {
  declare -a _update_args
  if [[ -n ${options[uid]} && ${options[uid]} != $_uid ]]; then
    _update_args+=("-u ${options[uid]}")
  fi

  if [[ -n ${options[gid]} && ${options[gid]} != $_gid ]]; then
    _update_args+=("-g ${options[gid]}")
  fi

  if [[ -n ${options[homedir]} && ${options[homedir]} != $_homedir ]]; then
    _update_args+=("-d ${options[homedir]}")
  fi

  if [[ -n ${options[shell]} && ${options[shell]} != $_shell ]]; then
    _update_args+=("-s ${options[shell]}")
  fi

  if [[ -n ${options[passwd]} && ${options[passwd]} != $_passwd ]]; then
    _update_args+=("-p ${options[passwd]}")
  fi

  local _group_update=false
  if [[ -n ${options[groups]} ]]; then
    string.split "${options[groups]}" ','
    for i in "${__split[@]}"; do
      if ! array.contains _groups $i ; then
        _group_update=true
      fi
    done
  fi

  if [[ $_group_update == "true" ]]; then
    _update_args+=("-G ${options[groups]}")
  fi

  log.debug "Updating user ${options[user]}"
  exec.capture_error usermod "${_update_args[@]}" "${options[user]}"

  if [[ ${options[sudo]} == "true" && ! -f "/etc/sudoers.d/${options[user]}" ]]; then
    exec.capture_error echo "${options[user]} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${options[user]}"
  fi
}

os.useradd.delete() {
  exec.capture_error userdel -f "${options[user]}"
}
