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
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.set_option state   "present"
  stdlib.options.set_option ppa     "__required__"
  stdlib.options.set_option refresh "true"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.apt_ppa/${options[ppa]}"

  stdlib.apt_ppa.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[ppa]} state: $stdlib_current_state, should be absent."
      stdlib.apt_ppa.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[ppa]} state: absent, should be present."
        stdlib.apt_ppa.create
        ;;
      present)
        stdlib.debug "${options[ppa]} state: present."
        ;;
    esac
  fi
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
  stdlib.mute apt-add-repository -y ppa:${options[ppa]}

  if [[ ${options[refresh]} == true ]]; then
    stdlib.mute apt-get update
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.apt_ppa.delete {
  stdlib.mute apt-add-repository -y -r ppa:${options[ppa]}

  if [[ ${options[refresh]} == true ]]; then
    stdlib.mute apt-get update
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
