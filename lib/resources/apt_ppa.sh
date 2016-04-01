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
# * ppa: The PPA. Required. namevar.
# * refresh: run apt-get update if the PPA was modified. Default: true.
#
# === Example
#
# ```shell
# apt.ppa --ppa ppa:chris-lea/redis-server
# ```
#
function apt.ppa {
  waffles.subtitle "apt.ppa"

  if ! waffles.command_exists apt-add-repository ; then
    log.error "Cannot find apt-add-repository command."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option ppa     "__required__"
  waffles.options.create_option refresh "true"
  waffles.options.parse_options "$@"


  # Process the resource
  waffles.resource.process "apt.ppa" "${options[ppa]}"
}

function apt.ppa.read {
  local _repo_file_name="$(echo ${options[ppa]} | sed -e "s|[/:]|-|" -e "s|\.|_|")-*.list"
  if [ -f /etc/apt/sources.list.d/$_repo_file_name ]; then
    waffles_resource_current_state="present"
    return
  fi

  waffles_resource_current_state="absent"
}

function apt.ppa.create {
  exec.capture_error apt-add-repository -y ppa:${options[ppa]}

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update
  fi
}

function apt.ppa.delete {
  exec.capture_error apt-add-repository -y -r ppa:${options[ppa]}

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update
  fi
}
