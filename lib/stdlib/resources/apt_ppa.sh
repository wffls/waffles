# == Name
#
# stdlib.apt_ppa
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
# stdlib.apt_ppa --ppa ppa:chris-lea/redis-server
# ```
#
function stdlib.apt_ppa {
  stdlib.subtitle "stdlib.apt_ppa"

  if ! stdlib.command_exists apt-add-repository ; then
    stdlib.error "Cannot find apt-add-repository command."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option ppa     "__required__"
  stdlib.options.create_option refresh "true"
  stdlib.options.parse_options "$@"


  # Process the resource
  stdlib.resource.process "stdlib.apt_ppa" "${options[ppa]}"
}

function stdlib.apt_ppa.read {
  local _repo_file_name="$(echo ${options[ppa]} | sed -e "s|[/:]|-|" -e "s|\.|_|")-*.list"
  if [ -f /etc/apt/sources.list.d/$_repo_file_name ]; then
    stdlib_current_state="present"
    return
  fi

  stdlib_current_state="absent"
}

function stdlib.apt_ppa.create {
  stdlib.capture_error apt-add-repository -y ppa:${options[ppa]}

  if [[ ${options[refresh]} == "true" ]]; then
    stdlib.mute apt-get update
  fi
}

function stdlib.apt_ppa.delete {
  stdlib.capture_error apt-add-repository -y -r ppa:${options[ppa]}

  if [[ ${options[refresh]} == "true" ]]; then
    stdlib.mute apt-get update
  fi
}
