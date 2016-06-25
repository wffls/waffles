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
# apt.ppa --ppa ppa:chris-lea/redis-server
# ```
#
apt.ppa() {
  # Declare the resource
  waffles_resource="apt.pp"

  if ! waffles.command_exists apt-add-repository ; then
    log.error "Cannot find apt-add-repository command."
    return 1
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


  # Process the resource
  waffles.resource.process $waffles_resource "${options[ppa]}"
}

apt.ppa.read() {
  local _repo_file_name="$(echo ${options[ppa]} | sed -e "s|[/:]|-|" -e "s|\.|_|")-*.list"
  if [ -f /etc/apt/sources.list.d/$_repo_file_name ]; then
    waffles_resource_current_state="present"
    return
  fi

  waffles_resource_current_state="absent"
}

apt.ppa.create() {
  exec.capture_error apt-add-repository -y ppa:${options[ppa]}

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update
  fi
}

apt.ppa.delete() {
  exec.capture_error apt-add-repository -y -r ppa:${options[ppa]}

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update
  fi
}
