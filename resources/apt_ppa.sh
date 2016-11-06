# == Name
#
# apt.ppa
#
# === Description
#
# Manages PPA repositories
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * ppa: The PPA. Required.
# * refresh: run apt-get update if the PPA was modified. Default: true.
#
# === Example
#
# ```bash
# apt.ppa --ppa chris-lea/redis-server
# ```
#
apt.ppa() {
  # Declare the resource
  waffles_resource="apt.ppa"

  # Check if all dependencies are installed
  local _wrd=("apt-add-repository" "apt-get" "sed")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 2
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option ppa     "__required__"
  waffles.options.create_option refresh "true"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Local Variables
  local _source_file_name=""
  _source_file_name="$(echo ${options[ppa]} | sed -e "s|[/:]|-|" -e "s|\.|_|")" || true
  if [[ -z $_source_file_name ]]; then
    log.error "Unable to determine the name of the sources.list file"
    return 1
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[ppa]}"
}

apt.ppa.read() {
  if [ -f /etc/apt/sources.list.d/${_source_file_name}-*.list ]; then
    waffles_resource_current_state="present"
    return
  fi

  waffles_resource_current_state="absent"
}

apt.ppa.create() {
  exec.capture_error apt-add-repository -y ppa:${options[ppa]}

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update || true
  fi
}

apt.ppa.delete() {
  exec.capture_error apt-add-repository -y -r ppa:${options[ppa]}
  exec.capture_error rm /etc/apt/sources.list.d/${_source_file_name}-*.list

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update || true
  fi
}
