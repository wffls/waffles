# == Name
#
# dnf.repo
#
# === Description
#
# Manages dnf/yum repositories
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * file: name of the file in /etc/yum.repos.d/. Required. The file _must_ exist already.
# * name: name of the repo. Required.
# * description: A short description of the repo. Optional.
# * baseurl: URL location of the repo. Optional.
# * skip: Skip the repo if unavailable. Optional. Default 1.
# * enabled: Enable this repository. Optional. Default 1.
# * gpgcheck: Check RPMs for this repo. Optional. Default 0.
# * gpgkey: Location of the key to check. Optional. Default "".
#
# === Example
#
# ```bash
# dnf.repo --file fedora-negativo17.repo --name negativo17 --description \
#   "Negativo 17's repo" --baseurl 'http://negativo17.org/repos/flash-plugin/fedora-$releasever/$basearch/'
# ```
#
dnf.repo() {
  # Declare the resource
  waffles_resource="dnf.repo"

  local _wrd=("grep" "sed")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state       "present"
  waffles.options.create_option file        "__required__"
  waffles.options.create_option name        "__required__"
  waffles.options.create_option description "__required__"
  waffles.options.create_option baseurl     "__required__"
  waffles.options.create_option skip        "1"
  waffles.options.create_option enabled     "1"
  waffles.options.create_option gpgcheck    "0"
  waffles.options.create_option gpgkey      ""
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Ensure the file exists. Exit early if it doesn't.
  if [[ ! -f "/etc/yum.repos.d/${options[file]}" ]]; then
    log.error "/etc/yum.repos.d/${options[file]} does not exist."
    return 1
  fi

  local _conf_names=(name baseurl enabled skip_if_unavailable gpgkey gpgcheck)
  local _resource_names=(description baseurl enabled skip gpgkey gpgcheck)

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

dnf.repo.read() {
  if ! ini_file.has_section "/etc/yum.repos.d/${options[file]}" "${options[name]}"; then
    waffles_resource_current_state="absent"
    return
  fi

  local _changed=0
  local _ini_opt=""
  for (( i=${#_conf_names[@]}-1 ; i>=0 ; i-- )); do
     _ini_opt=$(ini_file.get_option "/etc/yum.repos.d/${options[file]}" "${options[name]}" "${_conf_names[$i]}")
     if [[ "${_ini_opt}" != "${_conf_names[$i]}=${options[${_resource_names[$i]}]}" ]]; then
        ((_changed+=1))
     fi
  done

  if [[ "${_changed}" -gt "0" ]]; then
    waffles_resource_current_state="update"
  else
    waffles_resource_current_state="present"
  fi
}

dnf.repo.create() {
  exec.capture_error touch "/etc/yum.repos.d/${options[file]}"
  dnf.repo.update
}

dnf.repo.update() {
  log.info "Updating \"/etc/yum.repos.d/${options[file]}\""
  for (( i=${#_conf_names[@]}-1 ; i>=0 ; i-- )); do
    if waffles.noop; then
      log.debug "(noop) ini_file.set \"/etc/yum.repos.d/${options[file]}\" \"${options[name]}\" \"${_conf_names[$i]}\" \"${options[${_resource_names[$i]}]}\""
    else
      ini_file.set "/etc/yum.repos.d/${options[file]}" "${options[name]}" "${_conf_names[$i]}" "${options[${_resource_names[$i]}]}"
      if [[ $? -ne 0 ]]; then
        log.error "Could not set ${_conf_names[$i]}=${options[${_resource_names[$i]}]} in \"/etc/yum.repos.d/${options[file]}\""
      fi
    fi
  done
  if waffles.noop; then
    ini_file.beautify "/etc/yum.repos.d/${options[file]}"
  fi
}

dnf.repo.delete() {
  log.info "Removing ${options[name]} from \"/etc/yum.repos.d/${options[file]}\""

  # Remove all options
  for (( i=${#_conf_names[@]}-1 ; i>=0 ; i-- )); do
    if waffles.noop; then
      log.debug "(noop) ini_file.remove \"/etc/yum.repos.d/${options[file]}\" \"${options[name]}\" \"${_conf_names[$i]}\""
    else
      ini_file.remove "/etc/yum.repos.d/${options[file]}" "${options[name]}" "${_conf_names[$i]}"
      if [[ $? -ne 0 ]]; then
        log.error "Could not remove ${_conf_names[$i]} from \"/etc/yum.repos.d/${options[file]}\""
      fi
    fi
  done

  # Remove setion
  if waffles.noop; then
    log.debug "(noop) ini_file.remove_section \"/etc/yum.repos.d/${options[file]}\" \"${options[name]}\""
  else
    ini_file.remove_section "/etc/yum.repos.d/${options[file]}" "${options[name]}"
    ini_file.beautify "/etc/yum.repos.d/${options[file]}"
    if [[ $? -ne 0 ]]; then
      log.error "Could not remove section ${options[name]} from \"/etc/yum.repos.d/${options[file]}\""
    fi
  fi
}
